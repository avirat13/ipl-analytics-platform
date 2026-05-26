# IPL Analytics Platform

An end-to-end cricket analytics pipeline built on Google BigQuery and dbt, analyzing 260,920 ball-by-ball records across 17 IPL seasons. The project covers death bowling efficiency, pressure batting performance, venue bias, partnership analysis, and a custom Value Above Replacement (VAR) metric inspired by baseball's WAR statistic.

**Live dashboard**: https://datastudio.google.com/reporting/36c81911-d141-4c3f-bf8b-06d47acf2e8c

---

## Tech Stack

| Layer | Tool |
|---|---|
| Data Warehouse | Google BigQuery |
| Transformation | dbt (8 models, 6 tests) |
| Visualisation | Power BI, Looker Studio |
| Language | SQL |

---

## Pipeline Architecture

```
Raw CSVs (Kaggle)
      |
Google BigQuery
  matches_raw, deliveries_raw
      |
dbt Staging
  stg_matches, stg_deliveries
      |
dbt Intermediate
  int_match_context
  (pressure flags, running totals, wicket buckets, match phase)
      |
dbt Mart
  mart_death_bowling
  mart_pressure_batting
  mart_venue_bias
  mart_partnerships
  mart_var
      |
Power BI + Looker Studio
```

---

## Data Models

| Model | Description | Rows |
|---|---|---|
| stg_matches | Cleaned match data, one row per match | 1,095 |
| stg_deliveries | Cleaned ball-by-ball data | 260,920 |
| int_match_context | Enriched deliveries with pressure flags, running totals, wicket buckets | 260,920 |
| mart_death_bowling | Death over bowling leaderboard, minimum 300 balls | 62 |
| mart_pressure_batting | Batting performance in pressure vs normal situations, minimum 200 pressure balls | 66 |
| mart_venue_bias | Toss impact and batting conditions by venue, minimum 10 matches | 37 |
| mart_partnerships | All-time partnership analysis, minimum 10 matches together | 265 |
| mart_var | Value Above Replacement per batter per season, minimum 200 balls | 501 |

---

## Key Findings

**Death Bowling**

SP Narine ranks first in death economy at 7.4 — the only spinner in the top 10, outperforming elite pace bowlers. Bumrah ranks sixth at 8.17 despite his reputation, largely because he bowled in the higher-scoring modern era. Malinga ranks second at 7.8.

**Pressure Batting**

Pressure is defined as any delivery where the chasing team's required run rate exceeds 10. N Pooran has the highest pressure index — scoring at 174 SR under pressure vs 151 normally. Kohli's strike rate drops below his normal average under pressure, suggesting his value comes from volume rather than clutch performance.

**Venue Bias**

Mohali has the highest toss dependency at 70% — winning the toss at this venue almost guarantees a match win. 69% of toss winners across IPL history chose to field first, confirming that captains broadly recognise chasing as an advantage.

**Partnerships**

Kohli + de Villiers: 3,134 runs across 77 matches at a strike rate of 152 — the most prolific partnership in IPL history. Kohli appears in three of the top four partnerships, no other batter comes close.

**Value Above Replacement**

AB de Villiers ranked first by VAR in 2016 despite Kohli scoring more raw runs — the metric rewards quality of performance over volume. MS Dhoni has a negative career VAR, confirming the metric's limitation for finishers whose value lies in match awareness and wicket preservation rather than outscoring the average.

---

## Metric Definitions

**Match Phase**
- Powerplay: overs 1 to 6
- Middle: overs 7 to 15
- Death: overs 16 to 20

**Pressure Ball**
A delivery is tagged as a pressure ball when the batting team is chasing and the required run rate exceeds 10.

**Value Above Replacement**
For every ball faced, the average runs scored by all IPL batters in that exact situation (same phase, wickets fallen, inning) is subtracted from the batter's actual runs. The differences are summed across a season or career. Positive VAR indicates outperformance; negative VAR indicates underperformance relative to the average.

**Death Rating (composite)**
```
death_rating = (1 - economy/12) x 40 + (dot_ball_pct/100) x 35 + (wickets_per_over/1.5) x 25
```

---

## Dataset Notes

Source: Kaggle IPL ball-by-ball dataset. Covers all 17 completed IPL seasons from 2008 to 2024. The 2025 season is excluded due to limited data availability and the 2026 season is currently in progress. Seasons are labelled by the year they began (2007/08 becomes 2008, 2009/10 becomes 2010, 2020/21 becomes 2020). All tournament stages are included: league matches, qualifiers, eliminators, and finals.

---

## How to Run

Prerequisites: Google Cloud account with BigQuery access, dbt 1.11 or later.

```bash
git clone https://github.com/avirat13/ipl-analytics-platform
cd ipl-analytics-platform/ipl_dbt

# configure ~/.dbt/profiles.yml with BigQuery credentials

dbt run
dbt test
dbt docs generate && dbt docs serve
```