# Decision Responsibility Matrix (DRM)

> Include this section in every `05_DESIGN_PROPOSAL.md` for non-trivial features.
> Prevents "decision compression" where whoever moves fastest becomes the default decision-maker.

## Authority Assignments

| Decision Component | Assigned Role | Required Action |
|:---|:---|:---|
| **Architectural Sign-off** | [Name/Role] | Approval of Step 0 Proposal |
| **Override Authority** | [Name/Role] | Approval of any Tier 2+ Quality Gate bypass |
| **Red-Team Challenge** | [Name/Role] | Formal dissent/review session |
| **Final Shipping Rights** | [Name/Role] | Decision to move from Prototype to Product |

## Risk Classification

**Assigned Risk Tier:** [Tier 1-4]

| Tier | Category | Override Protocol | Required Authority |
|:---|:---|:---|:---|
| 1 | Informational/Style | Practitioner justification | Practitioner |
| 2 | Operational/Stability | Peer review (Red-Team) | Peer |
| 3 | Safety/Security | Decision Owner + Pre-Mortem | Decision Owner |
| 4 | Strategic/Ethical | Institutional Executive Review | Executive/Legal |

## Contextual Constraints

List specific regulatory, brand, or operational requirements that apply:

- [ ] [Constraint 1: e.g., "Handles PII — GDPR consent required"]
- [ ] [Constraint 2: e.g., "Financial calculations — deterministic audit trail required"]
- [ ] [Constraint 3: e.g., "Customer-facing — brand voice review required"]
