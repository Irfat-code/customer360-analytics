# ADR 001: Reason-Based, Tier-Aware Recommendations

## Status
Accepted

## Context
The first version of `recommended_actions` mapped churn risk category directly to a single generic action ("Trigger win-back campaign" for any High/Critical account). This produced the same recommendation for the vast majority of at-risk accounts regardless of company size, why they were at risk, or what a Customer Success team would realistically do differently.

## Decision
Recommendations are now driven by the specific underlying signal causing risk (inactivity, support ticket backlog, low NPS, missing subscription), not just the risk category. Wording was rewritten to read as a concrete next task ("Resolve outstanding critical support tickets before raising renewal") rather than a marketing-style label ("CSM-led intervention"). Owner and SLA are assigned based on account tier and ARR, mirroring how real Customer Success organizations route work.

## Consequences
- The model has more branches and is harder to read at a glance, but produces meaningfully different output across accounts.
- Demonstrates a more realistic data product than a single risk-to-action lookup table.
- Future risk signals (e.g. payment failures, declining usage trend) can be added as new branches without restructuring the model.