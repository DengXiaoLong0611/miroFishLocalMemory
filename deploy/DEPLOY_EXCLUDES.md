# Server Deploy Excludes

Use `deploy/rsync-exclude.txt` when copying this repo to a Linux server.

Purpose:
- keep only source code and required static assets
- exclude local virtual environments, model weights, uploads, logs, caches, and generated data
- avoid pushing or syncing machine-specific secrets and runtime residue

Typical excluded groups:
- local Python environments
- Node dependencies
- uploaded simulation/report data
- local logs and caches
- local model files
- database and JSONL artifacts

Recommended usage:

```bash
rsync -av --delete --exclude-from=deploy/rsync-exclude.txt ./ user@server:/path/to/mirofish/
```
