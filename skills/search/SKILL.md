---
name: search
description: Fast filename/path search across all drives using Everything (es.exe). Use for file discovery — "where is it?" — not content search.
triggers:
  - /search
  - find a file
  - where is
  - locate
  - search for files
  - which projects have
  - find files named
  - where are my
---

# Everything Search — Fast Cross-Drive File Discovery

You have access to [Everything](https://www.voidtools.com/) via `es.exe`, which maintains a real-time index of every file and folder across all NTFS drives and the WSL filesystem. Results return in ~50ms regardless of scope.

## When to Use Everything vs Built-in Tools

| Use Everything | Use Glob/Grep |
|---|---|
| "Where is that file?" (unknown location) | Searching within current project directory |
| Cross-drive/cross-project file discovery | Content search (what's **inside** files) |
| Finding files anywhere (Windows + WSL) by name | Pattern matching in known directory |
| "Which projects have package.json?" | Already know the directory |
| "Find all .env files on my system" | Need to read/grep file contents |

**Key distinction:** Everything searches **filenames and paths** only, not file contents. For content search, use Grep.

## How to Invoke

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/everything-search.sh" find <query> [options]
```

Or via justfile:
```bash
just search <query>
just search_ext <query> <ext>
just search_path <query> <path>
just search_dirs <query>
just search_size <query>
```

## Options

| Flag | Description | Example |
|------|-------------|---------|
| `--ext <ext>` | Filter by extension | `--ext json` |
| `--path <path>` | Scope to directory (WSL or Windows) | `--path /mnt/c/Users` |
| `--dirs` | Directories only | |
| `--files` | Files only | |
| `--size` | Include file sizes | |
| `--date` | Include modification dates | |
| `--regex` | Regex mode | |
| `-n <num>` | Max results (default: 25) | `-n 50` |
| `--raw` | Return Windows paths (skip conversion) | |

## Examples

```bash
# Find all CLAUDE.md files anywhere
bash "${CLAUDE_PLUGIN_ROOT}/scripts/everything-search.sh" find "CLAUDE.md"

# Find Supabase configs
bash "${CLAUDE_PLUGIN_ROOT}/scripts/everything-search.sh" find "supabase" --ext json

# Find package.json files under a user's home
bash "${CLAUDE_PLUGIN_ROOT}/scripts/everything-search.sh" find "package.json" --path "/mnt/c/Users"

# Find project directories
bash "${CLAUDE_PLUGIN_ROOT}/scripts/everything-search.sh" find "node_modules" --dirs -n 10

# Find Python files with sizes
bash "${CLAUDE_PLUGIN_ROOT}/scripts/everything-search.sh" find "*.py" --size --path "/home"
```

## Path Handling

- **Output paths** are automatically converted to WSL format (`/mnt/c/...` or `/home/...`)
- **Input paths** (in `--path`) accept both WSL (`/mnt/c/...`, `/home/...`) and Windows (`C:\...`) formats
- WSL distro name is auto-detected (no hardcoded paths)
- Use `--raw` to get Windows paths if needed

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Results found |
| 1 | No results |
| 2 | Everything service not running / timeout |
| 3 | es.exe not found |
