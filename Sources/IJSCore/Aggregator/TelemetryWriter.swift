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
        let dailyDir = corpusPath.dailyDirectory(for: metadata.timestamp)
        try createDirectoryIfNeeded(at: dailyDir)

        let metadataPath = corpusPath.metadataPath(for: metadata.timestamp)
        try writeJSON(metadata, to: metadataPath)

        if calibrations.count > 1 {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for (index, calibration) in calibrations.enumerated() {
                    let path = corpusPath.calibrationPath(for: metadata.timestamp, index: index)
                    let data = try self.encoder.encode(calibration)
                    group.addTask {
                        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
                    }
                }
                try await group.waitForAll()
            }
        } else if let calibration = calibrations.first {
            let path = corpusPath.calibrationPath(for: metadata.timestamp, index: 0)
            try writeJSON(calibration, to: path)
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
        let directories = dailyDirectories(in: corpusPath, startDate: startDate, endDate: endDate)
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
        let directories = dailyDirectories(in: corpusPath, startDate: startDate, endDate: endDate)
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

    // MARK: - Private Helpers

    private func createDirectoryIfNeeded(at path: String) throws {
        do {
            try FileManager.default.createDirectory(
                atPath: path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            throw IJSError.telemetryWriteFailed(reason: "Cannot create directory \(path): \(error.localizedDescription)")
        }
    }

    private func writeJSON<T: Encodable>(_ value: T, to path: String) throws {
        do {
            let data = try encoder.encode(value)
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        } catch let error as IJSError {
            throw error
        } catch {
            throw IJSError.telemetryWriteFailed(reason: "Cannot write \(path): \(error.localizedDescription)")
        }
    }

    private func dailyDirectories(
        in corpusPath: CorpusPath,
        startDate: Date,
        endDate: Date
    ) -> [String] {
        let projectDir = corpusPath.projectDirectory
        guard FileManager.default.fileExists(atPath: projectDir) else { return [] }

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        dayFormatter.timeZone = TimeZone(identifier: "UTC")
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")

        let startDay = dayFormatter.string(from: startDate)
        let endDay = dayFormatter.string(from: endDate)

        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: projectDir) else {
            return []
        }

        return contents
            .filter { $0 >= startDay && $0 <= endDay }
            .sorted()
            .map { "\(projectDir)/\($0)" }
            .filter { var isDir: ObjCBool = false; return FileManager.default.fileExists(atPath: $0, isDirectory: &isDir) && isDir.boolValue }
    }

    private static func readMetadataFiles(
        in directory: String,
        decoder: JSONDecoder
    ) throws -> [CheckResultMetadata] {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: directory) else {
            return []
        }
        return try files
            .filter { $0.hasSuffix("_metadata.json") }
            .sorted()
            .map { filename in
                let path = "\(directory)/\(filename)"
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path))
                    return try decoder.decode(CheckResultMetadata.self, from: data)
                } catch {
                    throw IJSError.telemetryReadFailed(reason: "Cannot read \(path): \(error.localizedDescription)")
                }
            }
    }

    private static func readCalibrationFiles(
        in directory: String,
        decoder: JSONDecoder
    ) throws -> [JudgmentCalibration] {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: directory) else {
            return []
        }
        return try files
            .filter { $0.contains("_calibration_") && $0.hasSuffix(".json") }
            .sorted()
            .map { filename in
                let path = "\(directory)/\(filename)"
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path))
                    return try decoder.decode(JudgmentCalibration.self, from: data)
                } catch {
                    throw IJSError.telemetryReadFailed(reason: "Cannot read \(path): \(error.localizedDescription)")
                }
            }
    }
}
