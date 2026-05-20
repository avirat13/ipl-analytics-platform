{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('ipl_analytics', 'deliveries_raw') }}
),

cleaned AS (
    SELECT
        CONCAT(CAST(match_id AS STRING), '-',
       CAST(inning AS STRING), '-',
       CAST(batting_team AS STRING), '-',
       CAST(ball AS STRING))                AS delivery_id,

        match_id,
        inning,
        ball,
        batting_team,
        bowling_team,
        batter,
        bowler,
        non_striker,
        batsman_runs,
        extra_runs,
        total_runs,
        NULLIF(extras_type, '')                     AS extras_type,
        is_wicket,
        NULLIF(player_dismissed, 'NA')              AS player_dismissed,
        NULLIF(dismissal_kind, 'NA')                AS dismissal_kind,
        NULLIF(fielder, 'NA')                       AS fielder,

        CASE
            WHEN ball BETWEEN 1 AND 36 THEN 'powerplay'
            WHEN ball BETWEEN 37 AND 90 THEN 'middle'
            WHEN ball BETWEEN 91 AND 120 THEN 'death'
        END                                         AS match_phase,

        CASE WHEN total_runs = 0 THEN TRUE ELSE FALSE END
                                                    AS is_dot_ball,
        CASE WHEN batsman_runs IN (4, 6) THEN TRUE ELSE FALSE END
                                                    AS is_boundary,
        CASE WHEN batsman_runs = 6 THEN TRUE ELSE FALSE END
                                                    AS is_six,
        CASE WHEN batsman_runs = 4 THEN TRUE ELSE FALSE END
                                                    AS is_four

    FROM source
)

SELECT * FROM cleaned