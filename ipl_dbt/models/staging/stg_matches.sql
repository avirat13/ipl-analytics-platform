-- models/staging/stg_matches.sql
{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('ipl_analytics', 'matches_raw') }}
),

cleaned AS (
    SELECT
        id                                          AS match_id,
        CASE
            WHEN season = '2020/21' THEN 2020
            WHEN season LIKE '%/%'
            THEN CAST(CONCAT('20', SUBSTR(season, 6, 2)) AS INT64)
            ELSE CAST(season AS INT64)
        END                                         AS season,
        season                                      AS season_raw,
        city,
        date,
        match_type,
        venue,
        team1,
        team2,
        toss_winner,
        toss_decision,
        NULLIF(winner, '')                          AS winner,
        NULLIF(result, '')                          AS result,
        SAFE_CAST(result_margin AS FLOAT64)         AS result_margin,
        SAFE_CAST(target_runs AS INT64)             AS target_runs,
        SAFE_CAST(target_overs AS FLOAT64)          AS target_overs,
        super_over,
        NULLIF(method, '')                          AS method,
        player_of_match,
        umpire1,
        umpire2,

        -- who batted first
        CASE
            WHEN toss_decision = 'bat' THEN toss_winner
            WHEN toss_decision = 'field' THEN
                CASE
                    WHEN toss_winner = team1 THEN team2
                    ELSE team1
                END
        END                                         AS batting_first_team,

        -- did toss winner win
        CASE
            WHEN winner = toss_winner THEN TRUE
            ELSE FALSE
        END                                         AS toss_winner_won

    FROM source
)

SELECT * FROM cleaned