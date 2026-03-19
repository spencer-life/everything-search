# Everything Search Plugin

Fast cross-drive filename search for WSL2 using [Everything](https://www.voidtools.com/)'s `es.exe`.

## What It Does

Searches filenames and paths (not content) across all NTFS drives and WSL filesystem in ~50ms. Use it when you need to find where a file lives — not what's inside it.

## When to Use

- User asks "where is...?", "find a file", "locate", "which projects have..."
- Cross-drive/cross-project file discovery
- The `/search` skill triggers this automatically

## When NOT to Use

- Content search → use Grep
- Searching within current project → use Glob
- Known directory → use Glob/Grep directly

## How It Works

The script auto-detects `es.exe` location and WSL distro name at runtime — no hardcoded paths. Output paths are converted to WSL format automatically.

## Quick Reference

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/everything-search.sh" find <query> [--ext json] [--path /mnt/c] [--dirs] [--size] [-n 50]
```
