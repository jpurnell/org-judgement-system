import Foundation

/// Ethical risk signals detected by the quality gate's automated auditors.
public enum EthicalFlag: String, Sendable, Codable {
    /// Data collection without meaningful user consent.
    case unauthorizedDataCollection
    /// UI patterns designed to trick users into unintended actions.
    case manipulativeUX
    /// Data transmission code missing a required consent guard.
    case missingConsentGuard
    /// Automated decision-making that legally requires human-in-the-loop.
    case automatedDecisionRequiringHumanReview
    /// Features that track or monitor users without disclosure.
    case surveillanceFeature
}

/// Where the quality gate was executed.
public enum Environment: String, Sendable, Codable {
    /// Developer's local machine.
    case local
    /// Continuous integration pipeline.
    case ci
}

/// A single issue found by a quality gate checker.
public struct Diagnostic: Sendable, Codable, Equatable {
    /// The error code from the quality gate error registry.
    public let errorCode: String
    /// Path to the file containing the issue.
    public let filePath: String
    /// Line number where the issue was detected.
    public let lineNumber: Int
    /// Human-readable description of the violation.
    public let message: String
    /// Whether the issue is eligible for the `--fix` flag.
    public let isFixable: Bool

    public init(
        errorCode: String,
        filePath: String,
        lineNumber: Int,
        message: String,
        isFixable: Bool
    ) {
        self.errorCode = errorCode
        self.filePath = filePath
        self.lineNumber = lineNumber
        self.message = message
        self.isFixable = isFixable
    }
}

/// The result of a single quality gate checker (e.g., SafetyAuditor, ConcurrencyAuditor).
public struct CheckerResult: Sendable, Codable, Equatable {
    /// Identifier matching the quality-gate-swift checker (e.g., "SafetyAuditor").
    public let checkerId: String
    /// Pass or fail status for this checker.
    public let status: String
    /// Individual issues found by this checker.
    public let diagnostics: [Diagnostic]

    public init(checkerId: String, status: String, diagnostics: [Diagnostic]) {
        self.checkerId = checkerId
        self.status = status
        self.diagnostics = diagnostics
    }
}

/// A documented override of a quality gate check, including the justification and authority.
public struct OverrideRecord: Sendable, Codable, Equatable {
    /// The diagnostic rule that was overridden.
    public let diagnosticID: String
    /// The practitioner's rationale for the override.
    public let justification: String
    /// Who performed the override.
    public let author: String
    /// The risk tier of the overridden rule.
    public let riskTier: RiskTier
    /// The authority level of the person approving the override.
    public let authorityLevel: AuthorityLevel

    public init(
        diagnosticID: String,
        justification: String,
        author: String,
        riskTier: RiskTier,
        authorityLevel: AuthorityLevel
    ) {
        self.diagnosticID = diagnosticID
        self.justification = justification
        self.author = author
        self.riskTier = riskTier
        self.authorityLevel = authorityLevel
    }
}

/// Extended quality gate result with judgment system fields.
///
/// Bridges the gap between technical pass/fail status and human discernment
/// by capturing decision ownership, override rationale, ethical flags, and
/// institutional consistency scoring alongside standard checker results.
public struct CheckResultMetadata: Sendable, Codable, Equatable {
    /// Repository or project identifier.
    public let projectID: String
    /// When the quality gate was executed.
    public let timestamp: Date
    /// Whether the gate ran locally or in CI.
    public let environment: Environment
    /// The stakeholder with authority to ship this artifact, per the DRM.
    public let decisionOwner: String
    /// Results from each quality gate checker.
    public let results: [CheckerResult]
    /// Documented overrides of quality gate checks.
    public let overrides: [OverrideRecord]
    /// The overall risk classification for this gate run.
    public let riskTier: RiskTier
    /// Ethical risk signals detected by automated auditors.
    public let ethicalFlags: [EthicalFlag]
    /// How consistent this implementation is with institutional lessons. Nil if not yet scored.
    public let consistencyScore: Double?

    /// Creates a new check result metadata record.
    /// - Parameters:
    ///   - projectID: Repository or project identifier.
    ///   - timestamp: When the gate was executed.
    ///   - environment: Local or CI.
    ///   - decisionOwner: Stakeholder with shipping authority.
    ///   - results: Results from each checker.
    ///   - overrides: Documented overrides.
    ///   - riskTier: Overall risk classification.
    ///   - ethicalFlags: Ethical risk signals.
    ///   - consistencyScore: Institutional consistency score, if available.
    public init(
        projectID: String,
        timestamp: Date,
        environment: Environment,
        decisionOwner: String,
        results: [CheckerResult],
        overrides: [OverrideRecord],
        riskTier: RiskTier,
        ethicalFlags: [EthicalFlag],
        consistencyScore: Double?
    ) {
        self.projectID = projectID
        self.timestamp = timestamp
        self.environment = environment
        self.decisionOwner = decisionOwner
        self.results = results
        self.overrides = overrides
        self.riskTier = riskTier
        self.ethicalFlags = ethicalFlags
        self.consistencyScore = consistencyScore
    }
}
