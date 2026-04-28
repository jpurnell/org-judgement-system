import Foundation

/// Errors specific to the Institutional Judgment System.
public enum IJSError: Error, Sendable, Equatable, LocalizedError {
    /// Override attempted without documented rationale.
    case unjustifiedOverride(diagnostic: String)
    /// Override authority level doesn't match risk tier requirement.
    case riskTierMismatch(required: AuthorityLevel, actual: AuthorityLevel)
    /// Failed to write telemetry artifacts to the corpus path.
    case telemetryWriteFailed(reason: String)
    /// Failed to read telemetry artifacts from the corpus path.
    case telemetryReadFailed(reason: String)
    /// Configuration file could not be loaded or parsed.
    case configurationError(reason: String)

    public var errorDescription: String? {
        switch self {
        case .unjustifiedOverride(let diagnostic):
            return "Override without justification: \(diagnostic)"
        case .riskTierMismatch(let required, let actual):
            return "Authority mismatch: requires \(required.rawValue), got \(actual.rawValue)"
        case .telemetryWriteFailed(let reason):
            return "Telemetry write failed: \(reason)"
        case .telemetryReadFailed(let reason):
            return "Telemetry read failed: \(reason)"
        case .configurationError(let reason):
            return "Configuration error: \(reason)"
        }
    }
}
