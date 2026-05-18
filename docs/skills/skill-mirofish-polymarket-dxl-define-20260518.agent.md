# Agent 简要：skill-mirofish-polymarket-dxl-define-20260518

用途：该文件为自动化 agent 调用主 Skill 的简要步骤与示例，便于在 CI/自动化脚本里直接复用。

步骤（最小化）：
1. 准备工作目录，放置 `00_resolution.md`、`02_odds_history.txt`、`03_background.md`、`04_recent_evidence.txt`。
2. 调用 `/api/graph/build` 上传文件，获取 `project_id`。
3. 调用 `/api/simulation/create` 得到 `simulation_id`。
4. 调用 `/api/simulation/prepare` 生成 agent profiles（可并行）。
5. 调用 `/api/report/generate` 并轮询直到完成，下载 `section_*.md`。

示例 curl（复制并替换 `<PROJECT_ID>` `<SIM_ID>`）：
```bash
curl -X POST "http://localhost:5001/api/graph/build" -F "project_name=polymarket_example" -F "simulation_requirement=$(cat 00_resolution.md)" -F "files=@02_odds_history.txt"
curl -s -X POST http://localhost:5001/api/simulation/create -H "Content-Type: application/json" -d '{"project_id":"<PROJECT_ID>"}' | jq .
curl -s -X POST http://localhost:5001/api/simulation/prepare -H "Content-Type: application/json" -d '{"simulation_id":"<SIM_ID>","parallel_profile_count":5}' | jq .
```

输出：agent 应保存所有原始 API 响应（用于审计）并把最终报告上传到项目目录或 CI artifacts。
