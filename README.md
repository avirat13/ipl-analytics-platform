# 🏏 IPL Analytics Platform

An end-to-end cricket analytics system analyzing **260,920 ball-by-ball records** across **17 IPL seasons (2008–2024)**. Built with BigQuery, dbt, Power BI, and Looker Studio — covering death bowling efficiency, pressure batting, venue bias, partnerships, and a custom Value Above Replacement (VAR) metric.

## 🔗 Live Dashboard
👉 [View Interactive Looker Studio Dashboard](https://datastudio.google.com/reporting/36c81911-d141-4c3f-bf8b-06d47acf2e8c)

---

## 🛠 Tech Stack

| Layer | Tool |
|---|---|
| Data Warehouse | Google BigQuery |
| Transformation | dbt (8 models, 6 tests) |
| Visualisation | Power BI, Looker Studio |
| Language | SQL |
| Version Control | Git, GitHub |

---

## 🏗 Pipeline Architecture

```
Raw CSVs (Kaggle)
      ↓
Google BigQuery (matches_raw, deliveries_raw)
      ↓
dbt Staging Layer
  ├── stg_matches       → cleaned match data
  └── stg_deliveries    → cleaned ball-by-ball data
      ↓
dbt Intermediate Layer
  └── int_match_context → enriched deliveries with pressure flags,
                          running totals, wicket buckets, match phase
      ↓
dbt Mart Layer
  ├── mart_death_bowling
  ├── mart_pressure_batting
  ├── mart_venue_bias
  ├── mart_partnerships
  └── mart_var
      ↓
Power BI + Looker Studio Dashboards
```

---

## 📊 Dashboard Pages

| Page | Analysis | Key Visual |
|---|---|---|
| Death Bowling | Economy rate leaderboard for death overs | Horizontal bar chart |
| Pressure Batting | Strike rate in high-pressure vs normal situations | Dual clustered bar |
| Venue Bias | Toss impact and batting conditions by venue | Clustered bar + pie charts |
| Partnerships | Most productive batting pairs in IPL history | Stacked bar + contribution split |
| VAR | Value Above Replacement — quality over volume | Column chart + line chart |

---

## 🔑 Key Findings

### Death Bowling
- **SP Narine** ranks #1 in death economy at **7.4** — remarkable for a spinner beating elite pace bowlers
- **JJ Bumrah** ranks only #6 at 8.17 — reflects higher-scoring modern IPL era he bowled in
- **SL Malinga** #2 at 7.8 — historically the most dangerous death bowler

### Pressure Batting
- **N Pooran** has the highest pressure index — scores **174 under pressure vs 151 normally**
- **V Kohli** pressure SR drops below his normal SR — volume scorer, not a clutch performer by this metric
- Pressure defined as: chasing with required run rate > 10

### Venue Bias
- **Mohali (PCA Stadium)** has the highest toss dependency at **70%** — winning toss almost guarantees a win
- Majority of IPL venues are chase-friendly — captains have figured this out
- **69% of toss winners** choose to field first across IPL history

### Partnerships
- **AB de Villiers + V Kohli**: **3,134 runs** across **77 matches** at SR 152 — the most prolific partnership in IPL history
- **V Kohli** appears in **3 of the top 4** partnerships — unmatched consistency as a partnership builder
- **CH Gayle + V Kohli**: 2,802 runs — second highest despite Gayle's limited tenure at RCB

### Value Above Replacement (VAR)
- **AB de Villiers** ranked #1 by VAR in 2016 despite Kohli scoring more raw runs — VAR rewards quality over volume
- **MS Dhoni** has negative career VAR — confirms the metric's limitation for finishers whose value lies in match awareness, not run-scoring above average
- VAR formula: sum of (actual runs − average runs for that situation) across all balls faced

---

## 📁 Data Models

| Model | Type | Description | Rows |
|---|---|---|---|
| `stg_matches` | Table | Cleaned match data — one row per match | 1,095 |
| `stg_deliveries` | Table | Cleaned ball-by-ball data | 260,920 |
| `int_match_context` | Table | Enriched deliveries with pressure flags, running totals, wicket buckets | 260,920 |
| `mart_death_bowling` | Table | Death over bowling leaderboard (min 300 balls) | 62 |
| `mart_pressure_batting` | Table | Pressure situation batting analysis (min 200 pressure balls) | 66 |
| `mart_venue_bias` | Table | Venue toss and batting bias (min 10 matches) | 37 |
| `mart_partnerships` | Table | All-time partnership analysis (min 10 matches together) | 265 |
| `mart_var` | Table | Value Above Replacement per batter per season | 501 |

---

## 🧪 Data Quality Tests

dbt tests run on every model refresh:

| Test | Column | Model |
|---|---|---|
| `unique` | `match_id` | `stg_matches` |
| `not_null` | `match_id` | `stg_matches` |
| `not_null` | `season` | `stg_matches` |
| `not_null` | `match_id` | `stg_deliveries` |
| `not_null` | `delivery_id` | `stg_deliveries` |
| `accepted_values` | `match_phase` | `stg_deliveries` |

---

## 📐 Key Metric Definitions

**Match Phase:**
- Powerplay: overs 1–6
- Middle: overs 7–15
- Death: overs 16–20

**Pressure Ball:**
A delivery is tagged as a pressure ball when:
- Inning = 2 (chasing team batting)
- Required run rate > 10

**Value Above Replacement (VAR):**
For every ball faced, subtract the average runs scored by all IPL batters in that exact situation (same phase, wickets fallen, inning). Sum across a season or career.

**Death Rating (composite):**
```
death_rating = (1 - economy/12) × 40 + (dot_ball_pct/100) × 35 + (wickets_per_over/1.5) × 25
```

---

## 📋 Dataset Notes

- **Source**: Kaggle IPL ball-by-ball dataset
- **Seasons covered**: 17 of 19 IPL seasons
- **Season labelling**: Seasons named by start year — 2007/08 → 2008, 2009/10 → 2010, 2020/21 → 2020
- **Match types**: All tournament stages included (League, Qualifier, Eliminator, Final)

---

## 🚀 How to Run

**Prerequisites:**
- Google Cloud account with BigQuery access
- dbt 1.11+
- Python 3.9+

**Setup:**
```bash
# Clone the repo
git clone https://github.com/avirat13/ipl-analytics-platform
cd ipl-analytics-platform/ipl_dbt

# Configure dbt profile
# Add BigQuery credentials to ~/.dbt/profiles.yml

# Run all models
dbt run

# Run tests
dbt test

# Generate docs
dbt docs generate
dbt docs serve
```

---
