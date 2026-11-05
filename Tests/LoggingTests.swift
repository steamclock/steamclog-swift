import XCTest
@testable import SteamcLog

final class LoggingTests: XCTestCase {
    private class Collector: SteamcLogDestination {
        var outputLevel: LogLevel = .debug
        var entries: [LogEntry] = []
        func write(_ entry: LogEntry) { entries.append(entry) }
    }

    func testDispatcherRespectsDestinationLevels() {
        let dispatcher = LogDispatcher()
        let chatty = Collector(), quiet = Collector()
        dispatcher.add(chatty, outputLevel: .verbose)
        dispatcher.add(quiet, outputLevel: .warn)

        dispatcher.log(.info, "hello", functionName: "f()", fileName: "/a/B.swift", lineNumber: 7)
        dispatcher.log(.error, "uh oh", functionName: "f()", fileName: "/a/B.swift", lineNumber: 8)

        XCTAssertEqual(chatty.entries.map(\.message), ["hello", "uh oh"])
        XCTAssertEqual(quiet.entries.map(\.message), ["uh oh"])
        XCTAssertTrue(chatty.entries[0].formattedMessage.hasSuffix(" [Info] [main] [B.swift:7] f() > hello"))
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
