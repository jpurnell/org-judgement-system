import Foundation

/// Writes and reads IJS telemetry artifacts as JSON files in the corpus.
///
/// All operations are async to avoid blocking the caller during file I/O.
/// Write operations use a single-writer model — concurrent writes to the
/// same daily directory are safe because filenames include HHmmss timestamps.
public actor TelemetryWriter {

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    /// Writes a CheckResultMetadata and any JudgmentCalibrations to the corpus.
    ///
    /// Creates the daily directory if it doesn't exist.
    ///
    /// - Throws: `IJSError.telemetryWriteFailed` if directory creation or file write fails.
    public func write(
        metadata: CheckResultMetadata,
        calibrations: [JudgmentCalibration],
        to corpusPath: CorpusPath
    ) async throws {
        let dailyDir = try sanitizedURL(corpusPath.dailyDirectory(for: metadata.timestamp), within: corpusPath.basePath)
        try createDirectoryIfNeeded(at: dailyDir)

        let metadataURL = try sanitizedURL(corpusPath.metadataPath(for: metadata.timestamp), within: corpusPath.basePath)
        try writeJSON(metadata, to: metadataURL)

        if calibrations.count > 1 {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for (index, calibration) in calibrations.enumerated() {
                    let url = try sanitizedURL(corpusPath.calibrationPath(for: metadata.timestamp, index: index), within: corpusPath.basePath)
                    let data = try self.encoder.encode(calibration)
                    group.addTask {
                        try data.write(to: url, options: .atomic)
                    }
                }
                try await group.waitForAll()
            }
        } else if let calibration = calibrations.first {
            let url = try sanitizedURL(corpusPath.calibrationPath(for: metadata.timestamp, index: 0), within: corpusPath.basePath)
            try writeJSON(calibration, to: url)
        }
    }

    /// Reads all metadata artifacts for a project within a date range (inclusive).
    ///
    /// Scans daily directories concurrently. Results are sorted by timestamp.
    ///
    /// - Throws: `IJSError.telemetryReadFailed` if deserialization fails.
    public func readMetadata(
        from corpusPath: CorpusPath,
        startDate: Date,
        endDate: Date
    ) async throws -> [CheckResultMetadata] {
        let directories = try dailyDirectoryURLs(in: corpusPath, startDate: startDate, endDate: endDate)
        guard !directories.isEmpty else { return [] }

        let allMetadata = try await withThrowingTaskGroup(
            of: [CheckResultMetadata].self
        ) { group in
            for dir in directories {
                let dec = self.decoder
                group.addTask {
                    try Self.readMetadataFiles(in: dir, decoder: dec)
                }
            }
            var results: [CheckResultMetadata] = []
            for try await batch in group {
                results.append(contentsOf: batch)
            }
            return results
        }

        return allMetadata.sorted { $0.timestamp < $1.timestamp }
    }

    /// Reads all calibration artifacts for a project within a date range (inclusive).
    ///
    /// Daily directories are scanned concurrently. Results are sorted by date.
    ///
    /// - Throws: `IJSError.telemetryReadFailed` if deserialization fails.
    public func readCalibrations(
        from corpusPath: CorpusPath,
        startDate: Date,
        endDate: Date
    ) async throws -> [JudgmentCalibration] {
        let directories = try dailyDirectoryURLs(in: corpusPath, startDate: startDate, endDate: endDate)
        guard !directories.isEmpty else { return [] }

        let allCalibrations = try await withThrowingTaskGroup(
            of: [JudgmentCalibration].self
        ) { group in
            for dir in directories {
                let dec = self.decoder
                group.addTask {
                    try Self.readCalibrationFiles(in: dir, decoder: dec)
                }
            }
            var results: [JudgmentCalibration] = []
            for try await batch in group {
                results.append(contentsOf: batch)
            }
            return results
        }

        return allCalibrations.sorted { $0.date < $1.date }
    }

    // MARK: - Path Sanitization

    private func sanitizedURL(_ path: String, within basePath: String) throws -> URL {
        let resolved = URL(fileURLWithPath: path).standardized.resolvingSymlinksInPath()
        let base = URL(fileURLWithPath: basePath).standardized.resolvingSymlinksInPath()
        guard resolved.path.hasPrefix(base.path) else {
            throw IJSError.telemetryWriteFailed(reason: "Path \(path) escapes corpus base \(basePath)")
        }
        return resolved
    }

    // MARK: - Private Helpers

    private func createDirectoryIfNeeded(at url: URL) throws {
        do {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            throw IJSError.telemetryWriteFailed(reason: "Cannot create directory \(url.path): \(error.localizedDescription)")
        }
    }

    private func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch let error as IJSError {
            throw error
        } catch {
            throw IJSError.telemetryWriteFailed(reason: "Cannot write \(url.path): \(error.localizedDescription)")
        }
    }

    private func dailyDirectoryURLs(
        in corpusPath: CorpusPath,
        startDate: Date,
        endDate: Date
    ) throws -> [URL] {
        let projectURL = URL(fileURLWithPath: corpusPath.projectDirectory).standardized.resolvingSymlinksInPath()
        // SAFETY: Path is resolved via standardized + resolvingSymlinksInPath before use
        guard FileManager.default.fileExists(atPath: projectURL.path) else { return [] }

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        dayFormatter.timeZone = TimeZone(identifier: "UTC")
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")

        let startDay = dayFormatter.string(from: startDate)
        let endDay = dayFormatter.string(from: endDate)

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: projectURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        let baseURL = URL(fileURLWithPath: corpusPath.basePath).standardized.resolvingSymlinksInPath()
        return contents
            .filter { url in
                let name = url.lastPathComponent
                return name >= startDay && name <= endDay
            }
            .filter { url in
                let resolved = url.resolvingSymlinksInPath()
                guard resolved.path.hasPrefix(baseURL.path) else { return false }
                var isDir: ObjCBool = false
                // SAFETY: Path validated against base via hasPrefix above
                return FileManager.default.fileExists(atPath: resolved.path, isDirectory: &isDir) && isDir.boolValue
            }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func readMetadataFiles(
        in directory: URL,
        decoder: JSONDecoder
    ) throws -> [CheckResultMetadata] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return []
        }
        return try files
            .filter { $0.lastPathComponent.hasSuffix("_metadata.json") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { fileURL in
                let standardized = fileURL.standardized
                do {
                    let data = try Data(contentsOf: standardized)
                    return try decoder.decode(CheckResultMetadata.self, from: data)
                } catch {
                    throw IJSError.telemetryReadFailed(reason: "Cannot read \(standardized.path): \(error.localizedDescription)")
                }
            }
    }

    private static func readCalibrationFiles(
        in directory: URL,
        decoder: JSONDecoder
    ) throws -> [JudgmentCalibration] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return []
        }
        return try files
            .filter { $0.lastPathComponent.contains("_calibration_") && $0.lastPathComponent.hasSuffix(".json") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { fileURL in
                let standardized = fileURL.standardized
                do {
                    let data = try Data(contentsOf: standardized)
                    return try decoder.decode(JudgmentCalibration.self, from: data)
                } catch {
                    throw IJSError.telemetryReadFailed(reason: "Cannot read \(standardized.path): \(error.localizedDescription)")
                }
            }
    }
}
