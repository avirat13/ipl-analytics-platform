{{ config(materialized='table') }}

WITH pressure_stats AS (
    SELECT
        batter,
        is_pressure_ball,
        SUM(batsman_runs)                               AS runs,
        COUNT(*)                                        AS balls_faced,
        SUM(CAST(is_wicket AS INT64))                   AS dismissals,
        ROUND(SUM(batsman_runs) * 100.0 / COUNT(*), 1) AS strike_rate,
        ROUND(SUM(CAST(is_dot_ball AS INT64)) * 100.0 / COUNT(*), 1)
                                                        AS dot_ball_pct
    FROM {{ ref('int_match_context') }}
    WHERE inning = 2
    GROUP BY batter, is_pressure_ball
    HAVING balls_faced >= 200
),

pressure AS (
    SELECT
        batter,
        runs                                            AS pressure_runs,
        balls_faced                                     AS pressure_balls,
        strike_rate                                     AS pressure_sr,
        dot_ball_pct                                    AS pressure_dot_pct,
        dismissals                                      AS pressure_dismissals
    FROM pressure_stats
    WHERE is_pressure_ball = TRUE
),

normal AS (
    SELECT
        batter,
        runs                                            AS normal_runs,
        balls_faced                                     AS normal_balls,
        strike_rate                                     AS normal_sr,
        dot_ball_pct                                    AS normal_dot_pct
    FROM pressure_stats
    WHERE is_pressure_ball = FALSE
),

combined AS (
    SELECT
        p.batter,
        p.pressure_runs,
        p.pressure_balls,
        p.pressure_sr,
        p.pressure_dot_pct,
        p.pressure_dismissals,
        n.normal_runs,
        n.normal_balls,
        n.normal_sr,
        n.normal_dot_pct,
        ROUND(p.pressure_sr - n.normal_sr, 1)          AS sr_under_pressure,
        ROUND(p.pressure_sr / NULLIF(n.normal_sr, 0), 2)
                                                        AS pressure_index
    FROM pressure p
    JOIN normal n USING (batter)
)

SELECT
    batter,
    pressure_runs,
    pressure_balls,
    pressure_sr,
    normal_sr,
    sr_under_pressure,
    pressure_index,
    pressure_dot_pct,
    pressure_dismissals,
    normal_runs,
    normal_balls,
    RANK() OVER (ORDER BY pressure_index DESC)          AS pressure_rank
FROM combined
ORDER BY pressure_index DESC