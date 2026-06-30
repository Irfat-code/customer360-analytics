# ADR 002: Health Score Weighting

## Status
Accepted

## Context
A single health score needed to combine subscription status, support history, and NPS into one comparable number per company, without any one signal dominating or being ignored.

## Decision
Weight the score as: NPS (30 pts), satisfaction (30 pts), active subscription (25 pts flat), minus a support burden penalty (up to -15 pts). Subscription status is treated as binary rather than graded, since a lapsed subscription is a fundamentally different situation than a graded dissatisfaction score.

## Consequences
- A company with no active subscription can still post a moderate health score if NPS and satisfaction are strong, which is intentional — it surfaces lapsed-but-happy accounts as good win-back candidates rather than burying them at the bottom.
- The weighting is a judgment call, not derived from real outcome data, since this project uses synthetic data. In a production setting, these weights would be tuned against actual churn outcomes.