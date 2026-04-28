# Judgment Calibration: [Incident Name]

**Date:** YYYY-MM-DD
**Decision Owner:** [Name — from Design Responsibility Matrix]
**Practitioner:** [Name or AI Agent ID]
**Risk Tier:** [Tier 1-4]

---

## Override Context

**Diagnostic Bypassed:** [Error code from Quality Gate, e.g., `FORBIDDEN_FORCE_UNWRAP`]
**Checker:** [Auditor that flagged the issue, e.g., `SafetyAuditor`]
**File:** [Path and line number]

---

## Root Cause Analysis

**Proximate Cause (Action):** [What specifically happened — use verbs]
- Example: "Bypassed the ConcurrencyAuditor to ship a feature before the Friday deadline."

**Chain of Inquiry:**
1. Why? [First-level cause]
2. Why? [Second-level cause]
3. Why? [Third-level cause — continue until you reach a root adjective]

**Root Cause (Adjective — describes the decision process, not the person):**
- Example: "The decision was **expedient** rather than **strategic**."
- Example: "The review process was **contextually naive** regarding production data sensitivity."

**Failed Step:** [Goals / Problems / Diagnosis / Design / Doing]
- Goals: Wrong priorities or unclear objectives
- Problems: Issue tolerated or overlooked
- Diagnosis: Root cause not found, hard conversations avoided
- Design: Flawed plan for how components interact
- Doing: Poor execution or follow-through

**Pattern Check:** Is this a one-off error or part of a recurring pattern? [One-off / Recurring]

---

## Red-Team Dissent (Required)

> Mandatory for all risk tiers. In the absence of a human red team, an AI-generated
> adversarial dissent must be documented. The purpose is to ensure alternatives are
> always considered before an override is accepted.

**Dissent Source:** [Human Red Team / AI-Generated Adversarial Review]
**Alternative Considered:** [What different approach or objection was raised?]
**Counter-Argument:** [Why is the override justified despite the dissent?]
**Resolution:** [How was the dissent resolved — accepted, rejected with rationale, or deferred?]

---

## Institutional Calibration

**Process Failure:** What did our *process* miss? (Not "what did the AI do wrong?")

**Proposed Quality Gate Update:** [Specific new rule or heuristic, if any]

**Proposed Policy Update:** [Change to Coding Rules or guidelines, if any]

**Pulse Contribution:** [2-3 sentence summary of the calibration lesson for the Institutional Pulse]
