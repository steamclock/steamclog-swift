import XCTest
@testable import SteamcLog

final class LoggingTests: XCTestCase {
    private class Collector: SteamcLogDestination {
        var entries: [LogEntry] = []
        func write(_ entry: LogEntry) { entries.append(entry) }
    }

    func testDispatcherRespectsDestinationLevels() {
        let dispatcher = LogDispatcher(preset: .debug)
        let chatty = Collector(), quiet = Collector()
        dispatcher.add(chatty, outputLevel: .fixed(.verbose))
        dispatcher.add(quiet, outputLevel: .fixed(.warn))

        dispatcher.log(.info, "hello", functionName: "f()", fileName: "/a/B.swift", lineNumber: 7)
        dispatcher.log(.error, "uh oh", functionName: "f()", fileName: "/a/B.swift", lineNumber: 8)

        XCTAssertEqual(chatty.entries.map(\.message), ["hello", "uh oh"])
        XCTAssertEqual(quiet.entries.map(\.message), ["uh oh"])
        XCTAssertTrue(chatty.entries[0].formattedMessage.hasSuffix(" [Info] [main] [B.swift:7] f() > hello"))
    }

    func testChangingConfigUpdatesDestinationsFollowingThePreset() {
        var clog = SteamcLog(Config(logLevel: .debug), sentryConfig: nil)
        let followsConsole = Collector(), fixed = Collector()
        clog.attach(destination: followsConsole, outputLevel: .console)
        clog.attach(destination: fixed, outputLevel: .fixed(.info))

        clog.debug("debug preset")
        clog.info("debug preset info")

        // Release turns the console off entirely.
        clog.config = Config(logLevel: .release)
        clog.debug("release preset")
        clog.info("release preset info")

        XCTAssertEqual(followsConsole.entries.map(\.message), ["debug preset", "debug preset info"])
        XCTAssertEqual(fixed.entries.map(\.message), ["debug preset info", "release preset info"])
    }

    /// Swapping config while other threads log shouldn't crash (run with Thread Sanitizer to catch regressions).
    func testChangingConfigWhileLoggingFromOtherThreads() {
        var clog = SteamcLog(Config(logLevel: .debug), sentryConfig: nil)
        let reader = clog
        DispatchQueue.concurrentPerform(iterations: 4) { worker in
            if worker == 0 {
                for i in 0..<500 { clog.config = Config(logLevel: i.isMultiple(of: 2) ? .release : .debug) }
            } else {
                for i in 0..<500 { reader.info("worker \(worker) line \(i)") }
            }
        }
    }

    /// Goes through SteamcLog's real init, so the file destination is wired up the way apps get it.
    func testSteamcLogWritesToLogFile() throws {
        let clog = SteamcLog(Config(logLevel: .debug), sentryConfig: nil)
        let file = try XCTUnwrap(clog.dispatcher.destinations.compactMap { $0 as? FileLogDestination }.first)

        clog.debug("end to end")
        clog.verbose("below the disk level")
        file.queue.sync {}

        let contents = try XCTUnwrap(clog.getLogFileContents())
        XCTAssertTrue(contents.contains("[Debug] [main] [LoggingTests.swift:"))
        XCTAssertTrue(contents.contains("testSteamcLogWritesToLogFile() > end to end"))
        XCTAssertFalse(contents.contains("below the disk level"))
    }

    func testAllLogFileURLsIncludesArchivesCurrentFileAndSystemLog() async throws {
        let clog = SteamcLog(Config(logLevel: .debug), sentryConfig: nil)
        let marker = "export \(UUID().uuidString)"
        clog.warn(marker)

        let urls = await clog.allLogFileURLs()
        XCTAssertEqual(urls.last, clog.logFileURL())
        XCTAssertEqual(urls.dropLast().map(\.lastPathComponent), urls.dropLast().map(\.lastPathComponent).sorted())
        if let previous = clog.previousLogFileURL() { XCTAssertEqual(urls.dropLast().last, previous) }
        // No flush here, allLogFileURLs waits for pending writes itself.
        XCTAssertTrue(try String(contentsOf: clog.logFileURL(), encoding: .utf8).contains(marker))

        let withSystemLog = await clog.allLogFileURLs(includeSystemLog: true)
        XCTAssertEqual(Array(withSystemLog.dropLast()), urls)
        XCTAssertEqual(withSystemLog.last?.lastPathComponent, "steamclog-oslog.txt")
        XCTAssertTrue(try String(contentsOf: XCTUnwrap(withSystemLog.last), encoding: .utf8).contains(marker))
    }

    /// Stands in for Sentry, which reads the log file as soon as it's handed a user report.
    func testUserReportIsOnDiskBeforeLaterDestinationsSeeIt() throws {
        final class FileReader: SteamcLogDestination {
            let url: URL
            var seen: [(message: String, fileName: String, onDisk: Bool)] = []
            init(url: URL) { self.url = url }
            func write(_ entry: LogEntry) {
                let contents = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
                seen.append((entry.message, entry.fileName, contents.contains(entry.message)))
            }
        }

        let clog = SteamcLog(Config(logLevel: .debug, requireRedacted: true, detailedLogsOnUserReports: true), sentryConfig: nil)
        let reader = FileReader(url: clog.logFileURL())
        clog.attach(destination: reader, outputLevel: .fixed(.error))

        let marker = UUID().uuidString
        clog.userReport("report \(marker)")
        clog.userReport("with object \(marker)", ["not": "redactable"])
        clog.error("error with object", ["not": "redactable"])

        XCTAssertEqual(reader.seen.map(\.message), [
            "report \(marker)",
            "with object \(marker): Object redacted due to config.requireRedacted set to true",
            "error with object",
        ])
        XCTAssertTrue(reader.seen[0].onDisk)
        XCTAssertTrue(reader.seen[1].onDisk)
        // The redacted paths used to report SteamcLog.swift as the call site.
        XCTAssertTrue(reader.seen.allSatisfy { $0.fileName.hasSuffix("LoggingTests.swift") }, "\(reader.seen.map(\.fileName))")
    }

    func testUserReportWithObjectKeepsItsMessage() {
        let clog = SteamcLog(Config(logLevel: .debug), sentryConfig: nil)
        let collector = Collector()
        clog.attach(destination: collector, outputLevel: .fixed(.error))

        clog.userReport("it broke", ["step": 3])

        XCTAssertEqual(collector.entries.map(\.message), ["it broke: {\"step\":3}"])
    }

    func testUserInfoAndErrorReachDestinations() {
        struct Plain: Error {}
        struct Safe: Error, Redacted { static var safeProperties = Set<String>() }

        let collector = Collector()
        let clog = SteamcLog(Config(logLevel: .debug), sentryConfig: nil)
        clog.attach(destination: collector, outputLevel: .fixed(.info))
        clog.info("info", userInfo: ["screen": "home"])
        clog.error("failed", Plain(), userInfo: ["attempt": 2])
        clog.userReport("report", userInfo: ["ticket": "abc"])

        let errorEntry = collector.entries.first { $0.level == .error }
        XCTAssertEqual(collector.entries.first?.userInfo["screen"] as? String, "home")
        XCTAssertEqual(errorEntry?.userInfo["attempt"] as? Int, 2)
        XCTAssertTrue(errorEntry?.userInfo[UserInfoKeys.error] is Plain)
        XCTAssertEqual(collector.entries.last?.userInfo["ticket"] as? String, "abc")
        XCTAssertNotNil(collector.entries.last?.userInfo[UserInfoKeys.detailedLogURLs])

        // With requireRedacted, only Redacted errors are passed along.
        let redacting = SteamcLog(Config(logLevel: .debug, requireRedacted: true), sentryConfig: nil)
        let redactedCollector = Collector()
        redacting.attach(destination: redactedCollector, outputLevel: .fixed(.error))
        redacting.error("plain", Plain())
        redacting.error("safe", Safe())
        XCTAssertNil(redactedCollector.entries[0].userInfo[UserInfoKeys.error])
        XCTAssertTrue(redactedCollector.entries[1].userInfo[UserInfoKeys.error] is Safe)

        // An error the caller puts in userInfo themselves goes through the same check.
        redacting.userReport("report", userInfo: [UserInfoKeys.error: Plain()])
        redacting.forwardedLog(level: .error, message: "forwarded", object: Plain(), functionName: "f()", fileName: "A.swift", lineNumber: 1)
        XCTAssertNil(redactedCollector.entries[2].userInfo[UserInfoKeys.error])
        XCTAssertNil(redactedCollector.entries[3].userInfo[UserInfoKeys.error])
    }

    func testSuppressedRedactedErrorIsDowngradedToWarning() {
        struct Safe: Error, Redacted { static var safeProperties = Set<String>() }

        let collector = Collector()
        let clog = SteamcLog(Config(logLevel: .debug, suppressError: { $0 is Safe }), sentryConfig: nil)
        clog.attach(destination: collector, outputLevel: .fixed(.warn))
        clog.error("cancelled", Safe())

        XCTAssertEqual(collector.entries.map(\.level), [.warn])
        XCTAssertNil(collector.entries.first?.userInfo[UserInfoKeys.error])
    }

    func testSentryBreadcrumbDataHasAttributesAndCallsite() {
        let entry = LogEntry(level: .info, message: "hi", functionName: "f()", fileName: "/a/B.swift", lineNumber: 7,
                             userInfo: ["screen": "home", UserInfoKeys.extraInfo: ["x": 1]])
        let data = SentryDestination.breadcrumbData(for: entry, attributes: ["screen": "home"])
        XCTAssertEqual(data?["screen"] as? String, "home")
        XCTAssertEqual(data?["file"] as? String, "B.swift:7")
        XCTAssertEqual(data?["function"] as? String, "f()")
        XCTAssertNil(SentryDestination.breadcrumbData(for: LogEntry(level: .info, message: "internal", isInternal: true), attributes: [:]))
    }

    /// `fatal()` crashes right after logging, so its line has to be written before `write` returns.
    func testFatalLineIsWrittenBeforeWriteReturns() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let url = dir.appendingPathComponent("steamclog.txt")
        let file = FileLogDestination(fileURL: url, maxTimeInterval: 600)
        file.open()

        file.write(LogEntry(level: .info, message: "just before", functionName: "f()", fileName: "/a/B.swift", lineNumber: 7))
        file.write(LogEntry(level: .fatal, message: "the end", functionName: "f()", fileName: "/a/B.swift", lineNumber: 8))

        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(contents.contains("f() > just before"))
        XCTAssertTrue(contents.contains("f() > the end"))
    }

    func testRotationFailureIsReportedWithStableErrorAndLoggingContinues() throws {
        let fileManager = FileManager.default
        let dir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        defer {
            try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dir.path)
            try? fileManager.removeItem(at: dir)
        }

        let url = dir.appendingPathComponent("steamclog.txt")
        let file = FileLogDestination(fileURL: url, maxTimeInterval: 600)
        var reported: [(LogLevel, String)] = []
        file.onInternalLog = { reported.append(($0, $1)) }
        file.open()

        // Read-only directory, so the archive move fails.
        try fileManager.setAttributes([.posixPermissions: 0o555], ofItemAtPath: dir.path)

        let entry = LogEntry(level: .info, message: String(repeating: "x", count: 1000), functionName: "f()", fileName: "/a/B.swift", lineNumber: 7)
        for _ in 0..<1100 { file.write(entry) }
        file.write(LogEntry(level: .info, message: "still logging", functionName: "f()", fileName: "/a/B.swift", lineNumber: 8))
        file.queue.sync {}

        XCTAssertTrue(reported.contains { $0.0 == .warn && $0.1.hasPrefix("Unable to rotate file \(url.path)") }, "\(reported)")
        XCTAssertTrue(reported.contains { $0.0 == .error && $0.1 == "Unable to rotate log file" }, "\(reported)")
        XCTAssertFalse(reported.contains { $0.0 == .error && $0.1 != "Unable to rotate log file" }, "\(reported)")
        XCTAssertTrue(try String(contentsOf: url, encoding: .utf8).contains("f() > still logging"))
    }

    func testFileRotatesBySizeAndKeepsTenArchives() throws {
        let fileManager = FileManager.default
        let dir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: dir) }

        // Old archives from previous launches, which should get trimmed.
        for day in 1...12 {
            fileManager.createFile(atPath: dir.appendingPathComponent(String(format: "steamclog_2020-01-%02d_000000.txt", day)).path, contents: nil)
        }

        let url = dir.appendingPathComponent("steamclog.txt")
        let file = FileLogDestination(fileURL: url, maxTimeInterval: 600)
        var reported: [String] = []
        file.onInternalLog = { reported.append($1) }
        file.open()

        let entry = LogEntry(level: .warn, message: String(repeating: "x", count: 1000), functionName: "f()", fileName: "/a/B.swift", lineNumber: 7)
        for _ in 0..<1100 { file.write(entry) } // a bit over 1MB
        file.queue.sync {}

        XCTAssertTrue(reported.contains { $0.hasPrefix("Rotated file") }, "\(reported)")

        let archives = try fileManager.contentsOfDirectory(atPath: dir.path).filter { $0.hasPrefix("steamclog_") }.sorted()
        XCTAssertEqual(archives.count, FileLogDestination.maxArchivedFiles)
        XCTAssertFalse(archives.contains("steamclog_2020-01-01_000000.txt"))

        let newest = try String(contentsOf: dir.appendingPathComponent(archives.last!), encoding: .utf8)
        XCTAssertTrue(newest.contains("[Warning] [main] [B.swift:7] f() > xxx"))

        let current = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(current.contains("SteamcLog writing log to:"))
    }
}
