{{ config(materialized='table') }}

-- Value Above Replacement (VAR)
-- Measures how many more runs a batter scored compared to
-- what an average IPL batter would score in identical situations
-- Situation defined by: match_phase + wicket_bucket + inning

WITH situation_baselines AS (
    -- Step 1: calculate average runs per ball per situation
    SELECT
        match_phase,
        wicket_bucket,
        inning,
        AVG(batsman_runs)                               AS avg_runs_per_ball,
        COUNT(*)                                        AS sample_size
    FROM {{ ref('int_match_context') }}
    WHERE match_phase IS NOT NULL
    GROUP BY match_phase, wicket_bucket, inning
),

batter_contributions AS (
    -- Step 2: for every ball, subtract baseline from actual
    SELECT
        i.batter,
        i.season,
        i.match_id,
        i.batsman_runs,
        b.avg_runs_per_ball,
        i.batsman_runs - b.avg_runs_per_ball            AS runs_above_avg,
        i.match_phase,
        i.wicket_bucket,
        i.inning
    FROM {{ ref('int_match_context') }} i
    JOIN situation_baselines b
        ON i.match_phase = b.match_phase
        AND i.wicket_bucket = b.wicket_bucket
        AND i.inning = b.inning
    WHERE i.match_phase IS NOT NULL
),

season_var AS (
    -- Step 3: sum contributions per batter per season
    SELECT
        batter,
        season,
        ROUND(SUM(runs_above_avg), 1)                   AS var_runs,
        COUNT(*)                                        AS balls_faced,
        SUM(batsman_runs)                               AS actual_runs,
        ROUND(AVG(batsman_runs) * 100, 1)               AS strike_rate,
        COUNT(DISTINCT match_id)                        AS matches

    FROM batter_contributions
    GROUP BY batter, season
    HAVING balls_faced >= 200
),

career_var AS (
    -- Step 4: aggregate career VAR across all seasons
    SELECT
        batter,
        ROUND(SUM(var_runs), 1)                         AS career_var,
        SUM(balls_faced)                                AS career_balls,
        SUM(actual_runs)                                AS career_runs,
        COUNT(DISTINCT season)                          AS seasons_played,
        COUNT(DISTINCT matches)                         AS total_matches
    FROM season_var
    GROUP BY batter
)

-- Final output: season VAR with career summary joined
SELECT
    s.batter,
    s.season,
    s.var_runs,
    s.balls_faced,
    s.actual_runs,
    s.strike_rate,
    s.matches,
    c.career_var,
    c.career_balls,
    c.career_runs,
    c.seasons_played,
    RANK() OVER (
        PARTITION BY s.season
        ORDER BY s.var_runs DESC
    )                                                   AS season_var_rank,
    RANK() OVER (
        ORDER BY c.career_var DESC
    )                                                   AS career_var_rank
FROM season_var s
JOIN career_var c USING (batter)
ORDER BY s.season, season_var_rank