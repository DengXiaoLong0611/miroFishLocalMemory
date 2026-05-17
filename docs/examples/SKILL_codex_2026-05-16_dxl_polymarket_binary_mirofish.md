# SKILL: Codex 2026-05-16 DXL Polymarket Binary Event Forecasting with MiroFish

## Purpose

Use MiroFish to analyze Polymarket-style binary, externally verifiable events. The goal is not to make a single LLM guess. The workflow turns a market into a structured evidence graph, creates evidence-bearing social agents, simulates several plausible information paths, and compares the simulated belief movement with Polymarket odds history.

Use this skill for markets like:

- "Will X happen by date Y?"
- "Will organization X publish/approve/launch/settle Z before deadline?"
- "Will a named external source resolve YES under explicit criteria?"

Do not use this skill for subjective markets, meme markets without clear resolution criteria, or markets where the resolving source is unclear.

## Required Inputs

Prepare one MiroFish project per Polymarket market. MiroFish supports these upload formats in this codebase:

- `.txt`
- `.md`
- `.markdown`
- `.pdf`

Upload at least four files:

1. `resolution.txt`
   - Exact Polymarket question.
   - YES criteria.
   - NO criteria.
   - Resolution deadline and any grace period.
   - Resolution source and what counts as acceptable evidence.
   - Edge cases that do not count.

2. `background.md`
   - Entity background.
   - Product/person/organization history.
   - Key dependencies.
   - Comparable historical cases.
   - Known bottlenecks and incentives.

3. `news_recent.txt`
   - Recent evidence table.
   - Recommended row format:
     `timestamp | headline | summary | source | credibility(0-1) | direction(YES/NO/neutral) | evidence_type`

4. `odds_history.txt`
   - Polymarket odds history.
   - Recommended row format:
     `timestamp | yes_price | volume | open_interest | notes`
   - If open interest is unavailable, use empty value but keep the column.

Optional but useful files:

- `counterevidence.md`: strongest NO evidence and why it matters.
- `source_registry.md`: source reliability notes.
- `actor_map.md`: likely entities that can affect or reveal the outcome.
- `timeline.md`: strict chronological timeline.
- `market_metadata.json.txt`: market id, slug, token ids, condition id, end date, tags.

## Download Polymarket Market Metadata

Use Polymarket public APIs. No wallet or API key is needed for market discovery and price history.

Official API split:

- Gamma API: `https://gamma-api.polymarket.com`
  - Use for market/event discovery and metadata.
- CLOB API: `https://clob.polymarket.com`
  - Use for orderbook prices, spreads, midpoints, and historical token prices.
- Data API: `https://data-api.polymarket.com`
  - Use for trades, holders, open interest, and activity when needed.

From a Polymarket URL, extract the event slug after `/event/`.

```bash
slug="fed-decision-in-october"
curl -s "https://gamma-api.polymarket.com/events/slug/${slug}" > event.json
```

If the event endpoint is not enough, query markets directly:

```bash
curl -s "https://gamma-api.polymarket.com/markets?slug=${slug}" > market.json
```

For broad discovery:

```bash
curl -s "https://gamma-api.polymarket.com/events?active=true&closed=false&order=volume_24hr&ascending=false&limit=100"
```

Record these fields into `market_metadata.json.txt`:

- event slug
- market id
- question
- description
- resolution source
- end date
- outcomes
- outcome prices
- `clobTokenIds`
- condition id
- active/closed status
- volume, liquidity, open interest if available

For a binary market, map the `Yes` outcome to its matching CLOB token id. In Gamma responses, `outcomes`, `outcomePrices`, and `clobTokenIds` may be JSON-encoded strings. Parse them and align by index.

## Download Odds History

Use the YES token id, not the human market slug, for CLOB price history.

Single token:

```bash
yes_token_id="TOKEN_ID_HERE"
curl -s "https://clob.polymarket.com/prices-history?market=${yes_token_id}&interval=max&fidelity=60" > yes_price_history.json
```

Absolute date range:

```bash
start_ts=1714521600
end_ts=1717200000
curl -s "https://clob.polymarket.com/prices-history?market=${yes_token_id}&startTs=${start_ts}&endTs=${end_ts}&fidelity=60" > yes_price_history.json
```

Batch history, up to 20 token ids:

```bash
curl -s --request POST "https://clob.polymarket.com/batch-prices-history" \
  --header "Content-Type: application/json" \
  --data '{"markets":["TOKEN_ID_1","TOKEN_ID_2"],"interval":"max","fidelity":60}' \
  > batch_price_history.json
```

Current best bid/ask:

```bash
curl -s "https://clob.polymarket.com/price?token_id=${yes_token_id}&side=BUY"
curl -s "https://clob.polymarket.com/price?token_id=${yes_token_id}&side=SELL"
```

Normalize `yes_price_history.json` into `odds_history.txt`:

```text
SECTION: TIME_SERIES_ODDS
# timestamp | yes_price | volume | open_interest | notes
2026-04-01T00:00:00Z | 0.47 |  |  | CLOB prices-history fidelity=60
```

If volume/open interest is important, supplement with Data API or Gamma fields. Keep odds as evidence, not as ground truth.

## Evidence Encoding Rules

MiroFish performs better when documents distinguish fact types clearly.

Use these labels in uploaded text:

- `RESOLUTION_RULE`: exact YES/NO criteria.
- `OFFICIAL_EVIDENCE`: filing, company announcement, regulator page, official API, court record.
- `MARKET_SIGNAL`: odds, volume, open interest, spread movement.
- `MEDIA_SIGNAL`: reporting, leaks, analyst notes.
- `COUNTEREVIDENCE`: facts that weaken YES.
- `DEPENDENCY`: approval, certification, logistics, legal process, governance vote.
- `DEADLINE`: cutoff, grace period, reporting lag.
- `ACTOR`: entity capable of causing or revealing the outcome.

Avoid uploading raw noisy dumps without timestamps. Every important claim should have a date and source.

## MiroFish Build Method

1. Create a new MiroFish project.
2. Upload the prepared `.txt`, `.md`, `.markdown`, or `.pdf` files.
3. Generate ontology.
4. Build graph.
5. Inspect graph before simulation.

For binary verifiable-event forecasting, the ontology should usually contain:

- Organization
- Person
- GovernmentAgency or Regulator
- Product or Object
- MarketDataPlatform
- MediaOutlet
- CertificationLaboratory
- WebArchiveService
- LegalDocument or Filing
- Event
- Deadline
- Evidence
- MarketSignal
- Concept

Preferred relationship types:

- `SUBMITS_TO`
- `APPROVES_OR_REJECTS`
- `REPORTS_ON`
- `ARCHIVES`
- `AFFECTS_PROBABILITY`
- `BLOCKS`
- `ENABLES`
- `CONTRADICTS`
- `CONFIRMS`
- `DEPENDS_ON`
- `RESOLVES_BY`
- `COMPETES_WITH`

Before simulation, inspect generated nodes. Do not let dates, bare numbers, generic concepts, or text chunks become active social agents. They may stay in the graph as facts, but the simulation agents should be evidence-bearing actors.

Good agents:

- The company/project at the center of the market.
- The official resolving source.
- Regulators, courts, agencies, exchanges, labs, or data providers.
- Credible media/source accounts.
- Competitors or counterparties if they create relevant pressure.
- Web archive / evidence-preservation actors when historical webpage proof matters.
- Polymarket or market-data observer only as a market-signal narrator.

Bad agents:

- Raw dates like `2026-12-31`.
- Raw values like `25000`.
- Generic words like `odds`, `timestamp`, `market`.
- Uploaded text chunks such as `TextEntry`.

If many bad agents are generated, slim the simulation profiles before running. Keep 8-20 core agents for a first pass.

## Simulation Design

Run more than one path. The point is to see whether different plausible information environments converge or diverge.

Recommended baseline:

- 3 paths minimum.
- 5 paths for serious markets.
- 7-11 paths when the market is high-value or evidence is ambiguous.

Recommended rounds:

- Fast smoke test: 12-24 rounds.
- Normal analysis: 45-72 rounds.
- Deep path exploration: 96-168 rounds.

Round interpretation:

- In this MiroFish setup, `minutes_per_round=60` means one simulated round equals one simulated hour.
- `45` rounds means a 45-hour simulated information window, not 45 real hours.
- Real runtime depends on number of agents, LLM speed, and recommendation settings.

Recommended path variants:

1. Base path
   - Use current evidence and current odds.

2. YES-favorable path
   - Add plausible but sourced acceleration signals, such as approval progress or official hints.

3. NO-favorable path
   - Add plausible delay or failure signals, such as certification backlog, missing filing, deadline risk.

4. Market-shock path
   - Keep facts unchanged, but include odds/volume spike and ask whether the graph can justify it.

5. Skeptical-source path
   - Downweight leaks/media and let only official evidence drive behavior.

Do not mix fake facts into the base path. Scenario paths must be labeled as hypothetical.

## What Agents Are Simulating

Each active point is not a literal human unless the graph entity is a person. In this workflow, agents are institutional or informational personas derived from graph entities. They simulate:

- what information the entity would plausibly publish,
- whether it would amplify, ignore, or dispute a claim,
- whether it would wait for official evidence,
- how it responds to other evidence-bearing actors,
- how public information flow could alter perceived YES probability.

The behavior basis is:

- uploaded documents,
- graph relationships,
- generated profile/persona,
- available platform actions,
- time/activity configuration,
- LLM action selection,
- platform state from previous posts.

Therefore, simulation output is a structured scenario trace, not a calibrated probability model by itself.

## Reading Outputs

After each path, export or inspect:

- action log counts by agent,
- posts/reposts/quotes/comments,
- evidence cited by agents,
- whether YES evidence or NO evidence dominated,
- whether agents converged or polarized,
- whether official sources acted or stayed silent,
- whether market odds movement is supported by evidence or only by narrative momentum.

Use this result table:

```text
path_id | setup | rounds | final_signal | yes_evidence | no_evidence | unresolved_gaps | simulated_probability_band | notes
base_01 | current evidence | 72 | NO-leaning | ... | ... | ... | 25-40% | ...
```

Probability band rule:

- Use a band, not a point estimate.
- Anchor the band to current Polymarket YES price.
- Move the band only when simulation identifies evidence that the current market likely underweights or overweights.
- Never output a trading recommendation unless the user explicitly asks for investment/trading analysis.

## Final Forecast Template

```markdown
# Market Forecast: <question>

## Resolution
- YES:
- NO:
- Deadline:
- Resolving source:

## Market Baseline
- Current YES price:
- 7d / 30d movement:
- Volume / open interest:

## Evidence Graph Summary
- Strongest YES evidence:
- Strongest NO evidence:
- Key dependencies:
- Missing evidence:

## Simulation Setup
- Paths:
- Rounds:
- Agents:
- Files uploaded:

## Simulation Findings
- Base path:
- YES-favorable path:
- NO-favorable path:
- Convergence/divergence:

## Forecast Band
- Estimated YES probability band:
- Relation to market price:
- Confidence:

## Watchlist
- Evidence that would move YES up:
- Evidence that would move YES down:
- Next dates to monitor:
```

## Automation Checklist

For another agent, execute this checklist:

1. Parse Polymarket URL and extract slug.
2. Fetch Gamma event/market metadata.
3. Parse binary outcomes and identify YES token id.
4. Fetch CLOB `prices-history` for YES token id.
5. Write `resolution.txt`, `background.md`, `news_recent.txt`, `odds_history.txt`, and `market_metadata.json.txt`.
6. Upload files to MiroFish.
7. Generate ontology and graph.
8. Inspect active simulation profiles.
9. Remove or ignore non-actor agents.
10. Run at least 3 paths.
11. Compare outputs against current odds.
12. Produce forecast using the template above.

## Local MiroFish Notes from Codex

For the local-memory codebase, the corrected simulation setup should:

- use the backend virtual environment Python for simulation subprocesses,
- use local `tiktoken` cache,
- force-clean old simulation action logs when rerunning,
- avoid OASIS default Twitter `twhin-bert` recommendation download for local runs by using a lightweight recommendation mode,
- keep simulation profiles small enough for practical iteration.

On Linux GPU servers, transfer code and dependency files, not local upload data, SQLite databases, logs, model caches, or virtual environments. Rebuild the environment on the server.

