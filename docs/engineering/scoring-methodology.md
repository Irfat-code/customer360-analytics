# Scoring Methodology

## Health score (0-100)

Calculated in [`customer_health.sql`](../../marts/customer360/models/marts/customer_health.sql) as a weighted composite of subscription status, customer sentiment (NPS and satisfaction), and support burden.

The reasoning behind the weighting: subscription status is treated as a near-binary signal, since a company is either paying or it isn't, while NPS and satisfaction are graded signals that should move the score proportionally. Support burden is treated as a penalty rather than a positive factor, since the absence of tickets isn't itself a sign of health.

For the exact weights and point values, see the model file directly — this avoids the documentation drifting out of sync if the scoring logic changes.

## Churn risk score (0-100)

Calculated in [`churn_risk.sql`](../../marts/customer360/models/marts/churn_risk.sql), layering engagement signals on top of the health score.

Risk increases with: no active subscription, no recent product usage, a high volume of critical support tickets, NPS detractors, low satisfaction, and a low underlying health score. No active subscription is weighted as the single largest factor, on the reasoning that a lapsed account is a stronger churn signal than any graded metric.

Scores are bucketed into Low, Medium, High, and Critical risk categories. See the model file for the exact thresholds.

## Why recommendations aren't a direct risk-to-action lookup

An earlier version of `recommended_actions` mapped risk category straight to a single action. This produced the same recommendation for most at-risk accounts, regardless of what was actually driving the risk. See [ADR 001](../decisions/001-tier-aware-recommendations.md) for the reasoning behind the current, signal-driven approach.