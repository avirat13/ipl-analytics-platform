{{ config(materialized='table') }}

WITH match_results AS (
    SELECT
        venue,
        match_id,
        toss_winner,
        toss_decision,
        winner,
        toss_winner_won,
        batting_first_team,
        CASE
            WHEN batting_first_team = winner THEN TRUE
            ELSE FALSE
        END                                             AS bat_first_won
    FROM {{ ref('stg_matches') }}
    WHERE winner IS NOT NULL
),

first_innings_scores AS (
    SELECT
        match_id,
        SUM(total_runs)                                 AS first_innings_score
    FROM {{ ref('int_match_context') }}
    WHERE inning = 1
    GROUP BY match_id
),

venue_stats AS (
    SELECT
        m.venue,
        COUNT(*)                                        AS matches_played,
        ROUND(AVG(f.first_innings_score), 1)            AS avg_first_innings_score,
        ROUND(COUNTIF(m.toss_winner_won) * 100.0 / COUNT(*), 1)
                                                        AS toss_win_pct,
        ROUND(COUNTIF(m.bat_first_won) * 100.0 / COUNT(*), 1)
                                                        AS bat_first_win_pct,
        COUNTIF(m.toss_decision = 'bat')                AS chose_bat,
        COUNTIF(m.toss_decision = 'field')              AS chose_field,
        ROUND(COUNTIF(m.toss_decision = 'field') * 100.0 / COUNT(*), 1)
                                                        AS field_first_pct
    FROM match_results m
    LEFT JOIN first_innings_scores f USING (match_id)
    GROUP BY venue
    HAVING matches_played >= 10
)

SELECT
    venue,
    matches_played,
    avg_first_innings_score,
    toss_win_pct,
    bat_first_win_pct,
    field_first_pct,
    chose_bat,
    chose_field,
    RANK() OVER (ORDER BY toss_win_pct DESC)            AS toss_impact_rank,
    CASE
        WHEN bat_first_win_pct >= 55 THEN 'Bat first ground'
        WHEN bat_first_win_pct <= 45 THEN 'Chase ground'
        ELSE 'Neutral'
    END                                                 AS ground_type
FROM venue_stats
ORDER BY toss_win_pct DESC