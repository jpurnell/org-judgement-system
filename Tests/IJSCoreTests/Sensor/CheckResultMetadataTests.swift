import Testing
import Foundation
@testable import IJSCore

@Suite("EthicalFlag")
struct EthicalFlagTests {

    @Test("All five cases exist with correct raw values")
    func rawValues() {
        #expect(EthicalFlag.unauthorizedDataCollection.rawValue == "unauthorizedDataCollection")
        #expect(EthicalFlag.manipulativeUX.rawValue == "manipulativeUX")
        #expect(EthicalFlag.missingConsentGuard.rawValue == "missingConsentGuard")
        #expect(EthicalFlag.automatedDecisionRequiringHumanReview.rawValue == "automatedDecisionRequiringHumanReview")
        #expect(EthicalFlag.surveillanceFeature.rawValue == "surveillanceFeature")
    }

    @Test("Codable round-trip for each case")
    func codableRoundTrip() throws {
        let allCases: [EthicalFlag] = [
            .unauthorizedDataCollection, .manipulativeUX, .missingConsentGuard,
            .automatedDecisionRequiringHumanReview, .surveillanceFeature,
        ]
        for flag in allCases {
            let data = try JSONEncoder().encode(flag)
            let decoded = try JSONDecoder().decode(EthicalFlag.self, from: data)
            #expect(decoded == flag)
        }
    }
}

@Suite("Environment")
struct EnvironmentTests {

    @Test("Both cases with raw string values")
    func rawValues() {
        #expect(Environment.local.rawValue == "local")
        #expect(Environment.ci.rawValue == "ci")
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        for env in [Environment.local, .ci] {
            let data = try JSONEncoder().encode(env)
            let decoded = try JSONDecoder().decode(Environment.self, from: data)
            #expect(decoded == env)
        }
    }
}

@Suite("OverrideRecord")
struct OverrideRecordTests {

    static let sample = OverrideRecord(
        diagnosticID: "FORBIDDEN_FORCE_UNWRAP",
        justification: "Necessary for legacy C-API compatibility",
        author: "j_doe_senior_dev",
        riskTier: .safety,
        authorityLevel: .decisionOwner
    )

    @Test("Golden path: all fields populated")
    func goldenPath() {
        let record = Self.sample
        #expect(record.diagnosticID == "FORBIDDEN_FORCE_UNWRAP")
        #expect(record.justification == "Necessary for legacy C-API compatibility")
        #expect(record.author == "j_doe_senior_dev")
        #expect(record.riskTier == .safety)
        #expect(record.authorityLevel == .decisionOwner)
    }

    @Test("Codable round-trip with camelCase keys")
    func codableRoundTrip() throws {
        let data = try JSONEncoder().encode(Self.sample)
        let decoded = try JSONDecoder().decode(OverrideRecord.self, from: data)
        #expect(decoded == Self.sample)

        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(json.contains("\"diagnosticID\""))
        #expect(json.contains("\"riskTier\""))
        #expect(json.contains("\"authorityLevel\""))
    }
}

@Suite("Diagnostic")
struct DiagnosticTests {

    static let sample = Diagnostic(
        errorCode: "QualityGateError.safetyViolation",
        filePath: "Sources/Math/Division.swift",
        lineNumber: 42,
        message: "Division by zero protection missing",
        isFixable: true
    )

    @Test("All fields accessible")
    func properties() {
        let d = Self.sample
        #expect(d.errorCode == "QualityGateError.safetyViolation")
        #expect(d.filePath == "Sources/Math/Division.swift")
        #expect(d.lineNumber == 42)
        #expect(d.message == "Division by zero protection missing")
        #expect(d.isFixable == true)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let data = try JSONEncoder().encode(Self.sample)
        let decoded = try JSONDecoder().decode(Diagnostic.self, from: data)
        #expect(decoded == Self.sample)
    }
}

@Suite("CheckerResult")
struct CheckerResultTests {

    static let sample = CheckerResult(
        checkerId: "SafetyAuditor",
        status: "fail",
        diagnostics: [DiagnosticTests.sample]
    )

    @Test("All fields accessible")
    func properties() {
        #expect(Self.sample.checkerId == "SafetyAuditor")
        #expect(Self.sample.status == "fail")
        #expect(Self.sample.diagnostics.count == 1)
    }

    @Test("Codable round-trip with camelCase checkerId")
    func codableRoundTrip() throws {
        let data = try JSONEncoder().encode(Self.sample)
        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(json.contains("\"checkerId\""))

        let decoded = try JSONDecoder().decode(CheckerResult.self, from: data)
        #expect(decoded == Self.sample)
    }
}

@Suite("CheckResultMetadata")
struct CheckResultMetadataTests {

    static func makeSample(
        ethicalFlags: [EthicalFlag] = [],
        overrides: [OverrideRecord] = [],
        consistencyScore: Double? = nil
    ) -> CheckResultMetadata {
        CheckResultMetadata(
            projectID: "BusinessMath-Lib",
            timestamp: Date(timeIntervalSince1970: 1_777_536_311),
            environment: .ci,
            decisionOwner: "j_doe_senior_dev",
            results: [CheckerResultTests.sample],
            overrides: overrides,
            riskTier: .safety,
            ethicalFlags: ethicalFlags,
            consistencyScore: consistencyScore
        )
    }

    @Test("Golden path: full metadata with results and overrides")
    func goldenPath() {
        let meta = Self.makeSample(
            overrides: [OverrideRecordTests.sample],
            consistencyScore: 0.85
        )
        #expect(meta.projectID == "BusinessMath-Lib")
        #expect(meta.environment == .ci)
        #expect(meta.decisionOwner == "j_doe_senior_dev")
        #expect(meta.results.count == 1)
        #expect(meta.overrides.count == 1)
        #expect(meta.riskTier == .safety)
        #expect(meta.consistencyScore == 0.85)
    }

    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let meta = Self.makeSample(
            ethicalFlags: [.manipulativeUX],
            overrides: [OverrideRecordTests.sample],
            consistencyScore: 0.92
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(meta)
        let decoded = try decoder.decode(CheckResultMetadata.self, from: data)
        #expect(decoded == meta)
    }

    @Test("camelCase JSON keys match MCP schema")
    func camelCaseKeys() throws {
        let meta = Self.makeSample(consistencyScore: 0.5)
        let data = try JSONEncoder().encode(meta)
        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(json.contains("\"projectID\""))
        #expect(json.contains("\"decisionOwner\""))
        #expect(json.contains("\"riskTier\""))
        #expect(json.contains("\"ethicalFlags\""))
        #expect(json.contains("\"consistencyScore\""))
    }

    @Test("Empty overrides array")
    func emptyOverrides() throws {
        let meta = Self.makeSample(overrides: [])
        let data = try JSONEncoder().encode(meta)
        let decoded = try JSONDecoder().decode(CheckResultMetadata.self, from: data)
        #expect(decoded.overrides.isEmpty)
    }

    @Test("Empty ethical flags array")
    func emptyEthicalFlags() throws {
        let meta = Self.makeSample(ethicalFlags: [])
        let data = try JSONEncoder().encode(meta)
        let decoded = try JSONDecoder().decode(CheckResultMetadata.self, from: data)
        #expect(decoded.ethicalFlags.isEmpty)
    }

    @Test("consistencyScore nil encodes correctly")
    func nilConsistencyScore() throws {
        let meta = Self.makeSample(consistencyScore: nil)
        let data = try JSONEncoder().encode(meta)
        let decoded = try JSONDecoder().decode(CheckResultMetadata.self, from: data)
        #expect(decoded.consistencyScore == nil)
    }

    @Test("consistencyScore populated")
    func populatedConsistencyScore() throws {
        let meta = Self.makeSample(consistencyScore: 0.75)
        let data = try JSONEncoder().encode(meta)
        let decoded = try JSONDecoder().decode(CheckResultMetadata.self, from: data)
        #expect(decoded.consistencyScore == 0.75)
    }

    @Test("Multiple results with multiple diagnostics")
    func multipleResults() throws {
        let result2 = CheckerResult(
            checkerId: "ConcurrencyAuditor",
            status: "fail",
            diagnostics: [
                Diagnostic(errorCode: "concurrency.1", filePath: "A.swift", lineNumber: 1, message: "msg1", isFixable: false),
                Diagnostic(errorCode: "concurrency.2", filePath: "B.swift", lineNumber: 2, message: "msg2", isFixable: true),
            ]
        )
        let meta = CheckResultMetadata(
            projectID: "Test",
            timestamp: Date(timeIntervalSince1970: 0),
            environment: .local,
            decisionOwner: "tester",
            results: [CheckerResultTests.sample, result2],
            overrides: [],
            riskTier: .operational,
            ethicalFlags: [],
            consistencyScore: nil
        )
        #expect(meta.results.count == 2)
        #expect(meta.results[1].diagnostics.count == 2)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(meta)
        let decoded = try decoder.decode(CheckResultMetadata.self, from: data)
        #expect(decoded.results.count == 2)
    }

    @Test("Date encodes as ISO 8601")
    func dateEncoding() throws {
        let meta = Self.makeSample()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(meta)
        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(json.contains("2026-"))
    }
}
