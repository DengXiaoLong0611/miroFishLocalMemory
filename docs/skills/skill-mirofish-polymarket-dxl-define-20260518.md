# Skill: MiroFish Polymarket DXL-Define 20260518
## 概要
本 Skill 面向 Polymarket 风格的二元（YES/NO）可验证事件，提供从数据采集、格式化、上传到 MiroFish 构图、创建模拟并生成报告的完整可自动化工作流。此文件为中文主版本（运维 + Agent 可用），包含必需输入模板、Polymarket 抓取规范、时间序列/新闻格式、模拟设计建议、自动化 checklist、示例 curl 命令、质量门与变更记录。

---

## 一、适用范围与前提
- 仅用于客观可验证的二元事件（能由公开来源判定 YES/NO）。
- 事件须有明确的 resolution 标准、截止时间与可接受的判定来源。
- 输入至少包含：`resolution`、`odds history`、`background`、`recent evidence`。

## 二、文件与模板（必须/推荐）
- 必须：
  - `00_resolution.md`（或 TXT）：明确 YES/NO 判定标准，截止时间，接受的判定来源/排除项。
  - `02_odds_history.txt`：SECTION: TIME_SERIES_ODDS 格式（见下）。
- 推荐：
  - `03_background.md`：实体、激励、已知瓶颈、时间线。
  - `04_recent_evidence.txt`：SECTION: NEWS_RECENT 表格化证据。
  - `01_market_metadata.md`：Polymarket slug、market id、YES token id、endDate 等。

模板示例（严格格式，便于后端解析）：

`00_resolution.md`
SECTION: RESOLUTION
# Market question: <精确市场问题>
YES criteria: <列出能判定 YES 的具体条件和可接受来源>
NO criteria: <列出能判定 NO 的具体条件>
Deadline: <2026-05-01T00:00:00Z>
Accepted sources: <官方来源、监管公告等>
Explicit exclusions: <不计入的情况>

`02_odds_history.txt`
SECTION: TIME_SERIES_ODDS
# market_slug: <slug>
# yes_token_id: <token id>
# source: Polymarket CLOB / Gamma
# timestamp | yes_odds | volume | open_interest | note
2026-05-01T00:00:00Z | 0.42 | 12500 | 25000 | daily close

`04_recent_evidence.txt`
SECTION: NEWS_RECENT
# timestamp | headline | summary | source | credibility(0-1) | directional_effect | url_or_file
2026-05-10T11:00:00Z | 官方提交报告 | 公司提交最终申请 | regulator.gov | 0.95 | YES+strong | https://...pdf

## 三、Polymarket 抓取规范（建议自动化）
- 优先使用官方端点：Gamma (`https://gamma-api.polymarket.com`) 获取市场 metadata；CLOB (`https://clob.polymarket.com`) 获取 prices-history、midpoint、spread。
- 关键步骤：
  1. 从市场 URL 提取 slug。  
  2. 调用 Gamma 获取 market/event 信息并解析 `outcomes` 与 `clobTokenIds`。  
  3. 确定 YES token id（用于历史价格抓取）。  
  4. 调用 CLOB `prices-history` 获取历史价格并规范化成 `TIME_SERIES_ODDS`。

示例 curl（采集 metadata）：
```bash
curl -s "https://gamma-api.polymarket.com/events/slug/${slug}" > event.json
curl -s "https://clob.polymarket.com/prices-history?market=${YES_TOKEN_ID}&interval=max&fidelity=60" > yes_price_history.json
```

注意遵守 Polymarket 使用条款与速率限制；如频繁抓取请申请官方 API 访问。

## 四、数据预处理规则
- 统一时间为 ISO 8601（UTC）；按时间排序。
- `odds` 取 0-1 范围（百分比除以 100）。
- 若缺 volume/open_interest，保留空列并在 header 注明数据来源限制。
- 为长文生成 100–300 字摘要并缓存 embeddings 以加速后续步骤。

## 五、MiroFish 模拟设计建议
- 路径（paths）：至少 3 条，建议 5 条为常规分析；7–11 条用于高价值/高不确定性事件。
- 轮数（rounds）：烟雾测试 12–24；常规 45–72；深度 96–168。`minutes_per_round` 可按需求调整（示例：60 表示每轮相当于一小时）。
- 角色(agent profiles)：保留 8–20 个核心 agent（公司/监管/官方来源/媒体/竞争者/数据平台）；避免把裸数字或文本块当作 agent。
- 路径示例：Base / YES-favorable / NO-favorable / Market-shock / Skeptical-source。

## 六、自动化 Checklist（实现脚本按序执行）
1. 输入：接受市场 URL 或 slug。  
2. 抓取 Gamma metadata，解析 YES token id。  
3. 抓取 CLOB prices-history，生成 `02_odds_history.txt`。  
4. 收集或手动准备 `00_resolution.md`、`03_background.md`、`04_recent_evidence.txt`。  
5. 调用 `/api/graph/build` 上传并构建图谱，获取 `project_id`。  
6. 调用 `/api/simulation/create` 获取 `simulation_id`。  
7. 调用 `/api/simulation/prepare` 生成 profiles（参数：并行数、是否使用 LLM 生成 profile）。  
8. 调用 `/api/report/generate` 并轮询进度，下载 `section_*.md` 报告。  

示例自动化伪代码可用 shell + curl 或 Python requests 实现。

## 七、示例 curl 操作（本地 MiroFish 后端假设 `http://localhost:5001`）
1) 构建图谱并上传文件：
```bash
curl -X POST "http://localhost:5001/api/graph/build" \
  -F "project_name=polymarket_example" \
  -F "simulation_requirement=$(cat 00_resolution.md)" \
  -F "files=@02_odds_history.txt" \
  -F "files=@03_background.md" \
  -F "files=@04_recent_evidence.txt"
```
2) 创建模拟：
```bash
curl -s -X POST http://localhost:5001/api/simulation/create -H "Content-Type: application/json" \
  -d '{"project_id":"<PROJECT_ID>"}' | jq .
```
3) 准备模拟：
```bash
curl -s -X POST http://localhost:5001/api/simulation/prepare -H "Content-Type: application/json" \
  -d '{"simulation_id":"<SIM_ID>","parallel_profile_count":5,"use_llm_for_profiles":true}' | jq .
```
4) 生成报告并轮询：
```bash
curl -s -X POST http://localhost:5001/api/report/generate -H "Content-Type: application/json" \
  -d '{"simulation_id":"<SIM_ID>"}' | jq .
```

## 八、质量门（Quality Gates）
- 在运行前：
  - `00_resolution.md` 必须明确，不能含模糊条款。  
  - YES token id 与 `odds_history` 的时间戳一致并有来源注释。  
  - 证据要分离 `source credibility` 与 `directional_effect`。  
- 在运行后：
  - 检查 agent 是否“杜撰”不存在的官方证据或修改 resolution 条款。  
  - 若 simulation 依赖市场赔率过强，应重新跑不含市场信号的路径作对比。

## 九、变更记录
- 2026-05-18: 合并并标准化为中文主版本，文件名规范 `skill-mirofish-polymarket-dxl-define-20260518`，增加示例 curl 与质量门。

---
文件保存在本仓库 `docs/skills/skill-mirofish-polymarket-dxl-define-20260518.md`，并建议把此版本同步到其他部署目录用于运维与自动化调用。
