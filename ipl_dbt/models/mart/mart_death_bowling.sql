{{ config(materialized='table') }}

-- Death over bowling leaderboard
-- match_phase = 'death' covers balls 91-120
-- Minimum 300 balls bowled in death overs to qualify

WITH death_balls AS (
    SELECT
        bowler,
        match_id,
        ball,
        total_runs,
        is_wicket,
        is_dot_ball,
        is_boundary,
        season
    FROM {{ ref('int_match_context') }}
    WHERE match_phase = 'death'
),

bowler_stats AS (
    SELECT
        bowler,
        COUNT(*)                                        AS balls_bowled,
        ROUND(COUNT(*) / 6.0, 1)                       AS overs_bowled,
        SUM(total_runs)                                 AS runs_conceded,
        ROUND(SUM(total_runs) * 6.0 / COUNT(*), 2)     AS economy_rate,
        SUM(is_wicket)                                  AS wickets,
        ROUND(SUM(is_wicket) * 6.0 / COUNT(*), 3)      AS wickets_per_over,
        ROUND(SUM(CAST(is_dot_ball AS INT64)) * 100.0 / COUNT(*), 1)  AS dot_ball_pct,
        ROUND(SUM(CAST(is_boundary AS INT64)) * 100.0 / COUNT(*), 1)  AS boundary_pct,
        COUNT(DISTINCT match_id)                        AS matches,
        COUNT(DISTINCT season)                          AS seasons_played
    FROM death_balls
    GROUP BY bowler
    HAVING balls_bowled >= 300
),

ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY economy_rate ASC)         AS economy_rank,
        RANK() OVER (ORDER BY dot_ball_pct DESC)        AS dot_ball_rank,
        RANK() OVER (ORDER BY wickets_per_over DESC)    AS wicket_rank,

        -- composite death bowling rating
        ROUND(
            (1 - (economy_rate / 12.0)) * 40 +
            (dot_ball_pct / 100.0) * 35 +
            (wickets_per_over / 1.5) * 25
        , 1)                                            AS death_rating

    FROM bowler_stats
)

SELECT
    economy_rank,
    bowler,
    overs_bowled,
    runs_conceded,
    wickets,
    economy_rate,
    wickets_per_over,
    dot_ball_pct,
    boundary_pct,
    death_rating,
    matches,
    seasons_played
FROM ranked
ORDER BY economy_rank