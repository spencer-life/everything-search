# Everything Search — Claude Code Plugin

Fast cross-drive filename search for Claude Code on WSL2, powered by [Everything](https://www.voidtools.com/).

## What It Does

Gives Claude Code the ability to search filenames and paths across all Windows drives and the WSL filesystem in ~50ms. Perfect for "where is that file?" questions.

## Prerequisites

1. **WSL2** — this plugin runs inside a WSL2 environment
2. **Everything** — install from [voidtools.com](https://www.voidtools.com/)
3. **Everything CLI (`es.exe`)** — enable in Everything: Tools → Options → CLI (or install separately)
4. **Everything service running** — Everything must be running on Windows for searches to work

## Install

Copy this plugin directory to your Claude Code plugins folder:

```bash
cp -r everything-search ~/.claude/plugins/
```

Or clone from GitHub:

```bash
git clone https://github.com/spencer-life/everything-search-plugin ~/.claude/plugins/everything-search
```

That's it. The plugin auto-detects your `es.exe` location and WSL distro name.

## Usage

### Via Skill (recommended)

Just ask Claude naturally:
- "Where is my package.json?"
- "Find all CLAUDE.md files"
- "Which projects have a Dockerfile?"

Or use the slash command: `/search <query>`

### Via Script

```bash
bash ~/.claude/plugins/everything-search/scripts/everything-search.sh find <query> [options]
```

### Options

| Flag | Description |
|------|-------------|
| `--ext <ext>` | Filter by extension (e.g., `json`, `py`) |
| `--path <dir>` | Scope to directory (WSL or Windows paths) |
| `--dirs` | Directories only |
| `--files` | Files only |
| `--size` | Include file sizes |
| `--date` | Include modification dates |
| `--regex` | Use regex matching |
| `-n <num>` | Max results (default: 25) |
| `--raw` | Return Windows paths (skip conversion) |

### Examples

```bash
# Find all Dockerfiles
bash scripts/everything-search.sh find "Dockerfile"

# Find JSON configs under a specific path
bash scripts/everything-search.sh find "config" --ext json --path /mnt/c/Users

# Find large directories
bash scripts/everything-search.sh find "node_modules" --dirs -n 10
```

## How It Works

- **es.exe auto-detection**: checks `$PATH`, then common install locations
- **WSL distro auto-detection**: reads `$WSL_DISTRO_NAME` env var, falls back to `wsl.exe --list`
- **Path conversion**: Windows paths (`C:\Users\...`) are converted to WSL format (`/mnt/c/Users/...`), and `\\wsl.localhost\` paths map back to `/home/...`
- **SessionStart hook**: a lightweight check on session start verifies Everything is available

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `es.exe not found` | Install Everything CLI or add its location to your PATH |
| `Timed out` | Make sure Everything is running on Windows |
| Wrong distro in paths | Set `WSL_DISTRO_NAME` env var in your shell profile |

## License

MIT
