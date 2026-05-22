{{ config(materialized='table') }}

WITH partnerships AS (
    SELECT
        -- canonical pair — alphabetical order so A-B and B-A are same pair
        LEAST(batter, non_striker)                      AS player_a,
        GREATEST(batter, non_striker)                   AS player_b,
        match_id,
        inning,
        match_phase,
        season,
        batsman_runs,
        total_runs,
        is_wicket,
        CAST(is_dot_ball AS INT64)                      AS is_dot_ball,
        CAST(is_boundary AS INT64)                      AS is_boundary
    FROM {{ ref('int_match_context') }}
),

partnership_stats AS (
    SELECT
        player_a,
        player_b,
        COUNT(DISTINCT match_id)                        AS matches_together,
        COUNT(*)                                        AS balls_together,
        SUM(total_runs)                                 AS runs_together,
        ROUND(SUM(total_runs) * 100.0 / COUNT(*), 1)   AS partnership_sr,
        ROUND(SUM(total_runs) * 6.0 / COUNT(*), 2)     AS run_rate,
        ROUND(SUM(is_dot_ball) * 100.0 / COUNT(*), 1)  AS dot_ball_pct,
        ROUND(SUM(is_boundary) * 100.0 / COUNT(*), 1)  AS boundary_pct,

        -- phase breakdown
        SUM(CASE WHEN match_phase = 'powerplay'
            THEN total_runs ELSE 0 END)                 AS powerplay_runs,
        SUM(CASE WHEN match_phase = 'middle'
            THEN total_runs ELSE 0 END)                 AS middle_runs,
        SUM(CASE WHEN match_phase = 'death'
            THEN total_runs ELSE 0 END)                 AS death_runs,

        COUNT(DISTINCT season)                          AS seasons_together
    FROM partnerships
    GROUP BY player_a, player_b
    HAVING matches_together >= 10
)

SELECT
    player_a,
    player_b,
    matches_together,
    balls_together,
    runs_together,
    partnership_sr,
    run_rate,
    dot_ball_pct,
    boundary_pct,
    powerplay_runs,
    middle_runs,
    death_runs,
    seasons_together,
    RANK() OVER (ORDER BY runs_together DESC)           AS runs_rank,
    RANK() OVER (ORDER BY partnership_sr DESC)          AS sr_rank
FROM partnership_stats
ORDER BY runs_together DESC