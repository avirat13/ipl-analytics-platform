{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('ipl_analytics', 'deliveries_raw') }}
),

cleaned AS (
    SELECT
        CONCAT(CAST(match_id AS STRING), '-',
               CAST(inning AS STRING), '-',
               CAST(source.`over` AS STRING), '-',
               CAST(ball AS STRING))                AS delivery_id,

        match_id,
        inning,
        source.`over` + 1                           AS over_num,
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
            WHEN source.`over` BETWEEN 0  AND 5  THEN 'powerplay'
            WHEN source.`over` BETWEEN 6  AND 14 THEN 'middle'
            WHEN source.`over` BETWEEN 15 AND 19 THEN 'death'
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