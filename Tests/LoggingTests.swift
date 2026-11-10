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
