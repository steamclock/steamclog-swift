//
//  FileLogDestination.swift
//  SteamcLog
//
//  Created by Brendan on 2020-01-21.
//  Copyright (c) 2020 Steamclock Software, Ltd. All rights reserved.
//

import Foundation

/// Writes logs to a file, archiving it alongside as `<name>_yyyy-MM-dd_HHmmss.<ext>` once it gets too old or too big.
/// Behaves the same as the XCGLogger `AutoRotatingFileDestination` it replaces.
final class FileLogDestination: SteamcLogDestination {
    static let maxFileSize: UInt64 = 1_048_576
    static let maxArchivedFiles = 10


    /// Reports housekeeping lines (file opened, rotated, failures) to the other destinations.
    var onInternalLog: ((LogLevel, String) -> Void)?

    private let fileURL: URL
    private let baseName: String
    private let fileExtension: String
    private let maxTimeInterval: TimeInterval
    let queue = DispatchQueue(label: "steamclog.fileDestination")
    private var handle: FileHandle?
    private var currentSize: UInt64 = 0
    private var startDate = Date()

    private static let archiveSuffixFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") // so archive names always sort by date
        formatter.dateFormat = "_yyyy-MM-dd_HHmmss"
        return formatter
    }()

    init(fileURL: URL, maxTimeInterval: TimeInterval) {
        self.fileURL = fileURL
        self.baseName = fileURL.deletingPathExtension().lastPathComponent
        self.fileExtension = fileURL.pathExtension
        self.maxTimeInterval = max(maxTimeInterval, 0)

        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
            currentSize = attributes[.size] as? UInt64 ?? 0
            startDate = attributes[.creationDate] as? Date ?? Date()
        }

        // A stale file from the last launch gets archived before we start appending to it.
        if shouldRotate {
            archive()
        }
    }

    /// Opens (or creates) the log file. Call once, after `onInternalLog` is set.
    /// `rotationNote` is written first when reopening after a rotation, as XCGLogger did.
    func open(rotationNote: String? = nil) {
        let fileManager = FileManager.default
        let appending = fileManager.fileExists(atPath: fileURL.path)
        if !appending {
            fileManager.createFile(atPath: fileURL.path, contents: nil)
        }

        do {
            handle = try FileHandle(forWritingTo: fileURL)
            if appending {
                try handle?.seekToEnd()
                try handle?.write(contentsOf: Data("-- ** ** ** --\n".utf8))
            }
        } catch {
            handle = nil
            onInternalLog?(.error, "Attempt to open log file for \(appending ? "appending" : "writing") failed: \(error.localizedDescription)")
            return
        }

        if let rotationNote {
            writeInternal(rotationNote)
        }

        let opened = "SteamcLog \(appending ? "appending" : "writing") log to: \(fileURL.absoluteString)"
        writeInternal(LogEntry.appDetails)
        onInternalLog?(.info, opened)
        writeInternal(opened)
    }

    func write(_ entry: LogEntry) {
        queue.async {
            self.append(entry.formattedMessage)
        }
    }

    /// Header lines are info level. Every preset's disk level is info or lower, so these are always written.
    private func writeInternal(_ message: String) {
        append(LogEntry(level: .info, message: message, isInternal: true).formattedMessage)
    }

    private func append(_ line: String) {
        let data = Data("\(line)\n".utf8)
        try? handle?.write(contentsOf: data)
        // Counts characters without the newline, as XCGLogger did, so files rotate at the same points as before.
        currentSize += UInt64(line.count)

        if shouldRotate {
            try? handle?.close()
            handle = nil
            open(rotationNote: archive())
        }
    }

    private var shouldRotate: Bool {
        if currentSize >= Self.maxFileSize { return true }
        return maxTimeInterval > 0 && Date().timeIntervalSince(startDate) >= maxTimeInterval
    }

    /// Returns a "Rotated file" note when the file was moved.
    @discardableResult
    private func archive() -> String? {
        defer {
            currentSize = 0
            startDate = Date()
            cleanUpArchives()
        }

        let fileManager = FileManager.default
        let archiveURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent(baseName + Self.archiveSuffixFormatter.string(from: Date()))
            .appendingPathExtension(fileExtension)

        // Already rotated this second, keep writing to the current file.
        guard !fileManager.fileExists(atPath: archiveURL.path) else { return nil }

        do {
            try fileManager.moveItem(at: fileURL, to: archiveURL)
        } catch {
            // Details (which differ per device) go out as a warning, and the error itself has a fixed message,
            // so Sentry groups every rotation failure into one issue.
            onInternalLog?(.warn, "Unable to rotate file \(fileURL.path) to \(archiveURL.path): \(error.localizedDescription)")
            onInternalLog?(.error, "Unable to rotate log file")
            return nil
        }

        let note = "Rotated file \(fileURL.path) to \(archiveURL.path)"
        onInternalLog?(.info, note)
        return note
    }

    private func cleanUpArchives() {
        let directory = fileURL.deletingLastPathComponent()
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        let archives = names
            .filter { $0.hasPrefix("\(baseName)_") && $0.hasSuffix(".\(fileExtension)") }
            .sorted(by: >)

        for name in archives.dropFirst(Self.maxArchivedFiles) {
            let url = directory.appendingPathComponent(name)
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                onInternalLog?(.error, "Unable to delete old archived log file \(url.path): \(error.localizedDescription)")
            }
        }
    }
}
