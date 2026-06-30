-- Mart: Next Best Action
-- Reason-based recommendations: the underlying signal drives the action,
-- not just the tier/risk label. Written as a concrete next task.

WITH risk AS (
    SELECT * FROM {{ ref('churn_risk') }}
),

actions AS (
    SELECT
        company_id,
        company_name,
        tier,
        status,
        total_mrr,
        total_arr,
        health_score,
        churn_risk_score,
        churn_risk_category,
        active_subscriptions,
        sessions_last_30_days,
        days_since_last_session,
        critical_tickets,
        total_support_tickets,
        avg_nps_score,
        nps_detractors,
        avg_satisfaction_score,

        -- Recommended action: driven by the specific signal causing the risk,
        -- not just the risk label. Written as a concrete next task.
        CASE
            -- No usage at all in 30+ days: the core problem is adoption stopped
            WHEN COALESCE(days_since_last_session, 999) > 30 AND active_subscriptions > 0
                THEN 'Contact the customer sponsor to understand why usage has stopped.'

            -- Heavy active user but drowning in support issues: fix the product experience first
            WHEN critical_tickets >= 5
                THEN 'Resolve outstanding critical support tickets before raising renewal.'

            -- No subscription left: this is a re-engagement, not a renewal conversation
            WHEN active_subscriptions = 0
                THEN 'Reach out to understand renewal intent and re-engage on a new plan.'

            -- Detractor feedback: listen before pitching anything
            WHEN avg_nps_score IS NOT NULL AND avg_nps_score <= 6
                THEN 'Schedule a feedback call to understand what is driving dissatisfaction.'

            -- High ARR account showing critical risk for other reasons: escalate
            WHEN churn_risk_category = 'Critical' AND total_arr > 50000
                THEN 'Escalate to Head of Customer Success for a sponsor-level call this week.'

            -- General critical risk without a single dominant cause
            WHEN churn_risk_category = 'Critical'
                THEN 'Book a retention call this week and review usage and support history beforehand.'

            -- High risk, Enterprise: check in directly
            WHEN churn_risk_category = 'High' AND tier = 'Enterprise'
                THEN 'Schedule a check-in call and agree on next steps to improve adoption.'

            -- High risk, Mid-Market: phone + email touch
            WHEN churn_risk_category = 'High' AND tier = 'Mid-Market'
                THEN 'Reach out by email and phone to discuss recent usage and offer help.'

            -- High risk, smaller accounts: lighter-touch follow-up
            WHEN churn_risk_category = 'High'
                THEN 'Send onboarding resources and invite the team to a live training session.'

            -- Medium risk: just stay close
            WHEN churn_risk_category = 'Medium'
                THEN 'Send a short check-in email and review activity again next week.'

            -- Healthy and growing usage: this is a sales conversation, not a CS one
            WHEN health_score >= 80 AND sessions_last_30_days > 5
                THEN 'Discuss additional features that match the customer''s current usage.'

            -- Promoter with strong health: ask for advocacy
            WHEN avg_nps_score >= 9 AND health_score >= 70
                THEN 'Ask whether the customer would be open to a referral or testimonial.'

            ELSE 'No action needed, continue tracking usage.'
        END                                          AS recommended_action,

        -- Owner: who on the team should act
        CASE
            WHEN churn_risk_category = 'Critical' AND total_arr > 50000
                THEN 'Head of Customer Success'
            WHEN tier = 'Enterprise'
                THEN 'Enterprise CSM'
            WHEN tier = 'Mid-Market' AND churn_risk_category IN ('Critical', 'High')
                THEN 'Customer Success Manager'
            WHEN tier = 'Mid-Market'
                THEN 'Customer Success Team'
            WHEN churn_risk_category IN ('Critical', 'High')
                THEN 'Lifecycle / Onboarding Team'
            WHEN health_score >= 80
                THEN 'Account Executive'
            ELSE 'No owner required'
        END                                          AS action_owner,

        -- SLA: how fast this needs to happen
        CASE
            WHEN churn_risk_category = 'Critical' AND total_arr > 50000
                THEN '24 hours'
            WHEN critical_tickets >= 5
                THEN '48 hours'
            WHEN churn_risk_category = 'Critical'
                THEN '3 days'
            WHEN churn_risk_category = 'High'
                THEN '7 days'
            WHEN churn_risk_category = 'Medium'
                THEN '14 days'
            ELSE 'No SLA'
        END                                          AS action_sla,

        -- Priority: for sorting the work queue, most urgent first
        CASE
            WHEN churn_risk_category = 'Critical' AND total_arr > 50000 THEN 1
            WHEN critical_tickets >= 5 THEN 2
            WHEN COALESCE(days_since_last_session, 999) > 30 AND active_subscriptions > 0 THEN 3
            WHEN churn_risk_category = 'Critical' THEN 4
            WHEN avg_nps_score IS NOT NULL AND avg_nps_score <= 6 THEN 5
            WHEN churn_risk_category = 'High' THEN 6
            WHEN churn_risk_category = 'Medium' THEN 7
            WHEN health_score >= 80 AND sessions_last_30_days > 5 THEN 8
            WHEN avg_nps_score >= 9 AND health_score >= 70 THEN 9
            ELSE 10
        END                                          AS action_priority,

        NOW()                                        AS calculated_at

    FROM risk
)

SELECT * FROM actions
ORDER BY action_priority ASC, total_arr DESC