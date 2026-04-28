import Foundation

/// Computes file paths within the IJS telemetry corpus directory structure.
///
/// All paths follow the convention:
/// `<basePath>/telemetry/<projectID>/YYYY-MM-DD/<HHmmss>_<artifact>.json`
public struct CorpusPath: Sendable, Equatable {
    /// Root of the corpus directory.
    public let basePath: String
    /// Project identifier used in the directory hierarchy.
    public let projectID: String

    public init(basePath: String, projectID: String) {
        self.basePath = basePath
        self.projectID = projectID
    }

    /// The telemetry root: `<basePath>/telemetry/<projectID>`
    public var projectDirectory: String {
        "\(basePath)/telemetry/\(projectID)"
    }

    /// Daily directory: `<basePath>/telemetry/<projectID>/YYYY-MM-DD`
    public func dailyDirectory(for date: Date) -> String {
        "\(projectDirectory)/\(Self.dayFormatter.string(from: date))"
    }

    /// Metadata artifact path: `<dailyDir>/<HHmmss>_metadata.json`
    public func metadataPath(for timestamp: Date) -> String {
        "\(dailyDirectory(for: timestamp))/\(Self.timeFormatter.string(from: timestamp))_metadata.json"
    }

    /// Calibration artifact path: `<dailyDir>/<HHmmss>_calibration_<index>.json`
    public func calibrationPath(for timestamp: Date, index: Int) -> String {
        "\(dailyDirectory(for: timestamp))/\(Self.timeFormatter.string(from: timestamp))_calibration_\(index).json"
    }

    private static let dayFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt
    }()

    private static let timeFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "HHmmss"
        fmt.timeZone = TimeZone(identifier: "UTC")
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt
    }()
}
