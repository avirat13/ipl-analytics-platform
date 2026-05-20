{{ config(materialized='table') }}

WITH deliveries AS (
    SELECT * FROM {{ ref('stg_deliveries') }}
),

matches AS (
    SELECT
        match_id,
        target_runs,
        batting_first_team,
        winner,
        toss_winner,
        toss_decision,
        venue,
        season
    FROM {{ ref('stg_matches') }}
),

with_context AS (
    SELECT
        d.*,
        m.target_runs,
        m.batting_first_team,
        m.winner,
        m.toss_winner,
        m.toss_decision,
        m.venue,
        m.season,

        -- running team score at this point in the innings
        SUM(d.total_runs) OVER (
            PARTITION BY d.match_id, d.inning
            ORDER BY d.ball
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                           AS runs_so_far,

        -- wickets fallen at this point
        SUM(d.is_wicket) OVER (
            PARTITION BY d.match_id, d.inning
            ORDER BY d.ball
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                           AS wickets_fallen,

        -- ball number within innings
        ROW_NUMBER() OVER (
            PARTITION BY d.match_id, d.inning
            ORDER BY d.ball
        )                                           AS ball_number,

        -- balls remaining
        120 - ROW_NUMBER() OVER (
            PARTITION BY d.match_id, d.inning
            ORDER BY d.ball
        )                                           AS balls_remaining

    FROM deliveries d
    LEFT JOIN matches m USING (match_id)
),

with_pressure AS (
    SELECT
        *,

        -- runs required for chasing team
        CASE
            WHEN inning = 2 AND target_runs IS NOT NULL
            THEN target_runs - runs_so_far
            ELSE NULL
        END                                         AS runs_required,

        -- required run rate
        CASE
            WHEN inning = 2
                AND target_runs IS NOT NULL
                AND balls_remaining > 0
            THEN ROUND((target_runs - runs_so_far) * 6.0 / balls_remaining, 2)
            ELSE NULL
        END                                         AS required_run_rate,

        -- current run rate
        CASE
            WHEN ball_number > 0
            THEN ROUND(runs_so_far * 6.0 / ball_number, 2)
            ELSE 0
        END                                         AS current_run_rate,

        -- pressure flag
        CASE
            WHEN inning = 2
                AND target_runs IS NOT NULL
                AND balls_remaining > 0
                AND (target_runs - runs_so_far) * 6.0 / balls_remaining > 10
            THEN TRUE
            WHEN inning = 1
                AND ball BETWEEN 1 AND 36
                AND wickets_fallen >= 3
            THEN TRUE
            ELSE FALSE
        END                                         AS is_pressure_ball,

        -- wicket bucket capped at 5 for VAR calculation
        LEAST(wickets_fallen, 5)                    AS wicket_bucket

    FROM with_context
)

SELECT * FROM with_pressure