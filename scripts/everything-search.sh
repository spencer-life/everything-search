#!/usr/bin/env bash
# everything-search.sh — WSL wrapper for Everything's es.exe CLI
# Provides fast filename/path search across Windows + WSL filesystems
# Usage: bash everything-search.sh find <query> [flags]

set -euo pipefail

DEFAULT_LIMIT=25
TIMEOUT_SEC=3

# --- Auto-detect es.exe ---

find_es_exe() {
	# 1. Check PATH first (works if WindowsApps is in WSL PATH)
	if command -v es.exe &>/dev/null; then
		command -v es.exe
		return
	fi

	# 2. Check common install locations
	local candidates=(
		"/mnt/c/Users/*/AppData/Local/Microsoft/WindowsApps/es.exe"
		"/mnt/c/Program Files/Everything/es.exe"
		"/mnt/c/Program Files (x86)/Everything/es.exe"
		"/mnt/c/ProgramData/chocolatey/bin/es.exe"
	)

	for pattern in "${candidates[@]}"; do
		# shellcheck disable=SC2086
		for match in $pattern; do
			if [[ -f "$match" ]]; then
				echo "$match"
				return
			fi
		done
	done

	return 1
}

ES_EXE="$(find_es_exe)" || {
	echo "ERROR: es.exe not found. Install Everything (https://www.voidtools.com/) and enable the es.exe CLI tool." >&2
	exit 3
}

# --- Auto-detect WSL distro name ---

detect_wsl_distro() {
	# Method 1: WSL_DISTRO_NAME env var (set by WSL runtime)
	if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
		echo "$WSL_DISTRO_NAME"
		return
	fi

	# Method 2: Parse /proc/version or /etc/os-release
	if [[ -f /etc/wsl.conf ]] || grep -qi microsoft /proc/version 2>/dev/null; then
		# Try wsl.exe --list to find the running distro
		local list
		list="$(wsl.exe --list --quiet 2>/dev/null | tr -d '\r' | head -1)" || true
		if [[ -n "$list" ]]; then
			echo "$list"
			return
		fi
	fi

	# Method 3: Default fallback
	echo "Ubuntu"
}

WSL_DISTRO="$(detect_wsl_distro)"

# --- Helpers ---

die() {
	echo "ERROR: $1" >&2
	exit "${2:-1}"
}

# Convert Windows paths to WSL paths in output
# Handles lines with column prefixes (size, date) before the path
convert_path() {
	local line="$1"
	local prefix="" path=""

	# \\wsl.localhost\<distro>\... → /path/...
	if [[ "$line" == *"\\\\wsl.localhost\\${WSL_DISTRO}"* ]] || [[ "$line" == *"\\wsl.localhost\\${WSL_DISTRO}"* ]]; then
		prefix="${line%%\\\\wsl*}"
		prefix="${prefix%%\\wsl*}"
		path="${line#*"$WSL_DISTRO"}"
		path="${path//\\//}"
		echo "${prefix}${path}"
		return
	fi

	# Drive letter path: extract prefix (size/date columns) before the drive letter
	if [[ "$line" =~ ^(.*[[:space:]])([A-Za-z]):\\ ]]; then
		prefix="${BASH_REMATCH[1]}"
		local drive="${BASH_REMATCH[2]}"
		drive="${drive,,}"
		path="${line#*"${BASH_REMATCH[2]}:\\"}"
		path="/mnt/${drive}/${path//\\//}"
		echo "${prefix}${path}"
		return
	fi

	# Drive letter at start of line (no prefix)
	if [[ "$line" =~ ^([A-Za-z]):\\ ]]; then
		local drive="${BASH_REMATCH[1]}"
		drive="${drive,,}"
		path="/mnt/${drive}${line:2}"
		path="${path//\\//}"
		echo "$path"
		return
	fi

	# Fallback: pass through
	echo "$line"
}

# Convert WSL path to Windows path for es.exe --path flag
wsl_to_win() {
	local p="$1"
	# /home/... → \\wsl.localhost\<distro>\home\...
	if [[ "$p" == /home/* || "$p" == /root/* || "$p" == /etc/* || "$p" == /var/* || "$p" == /tmp/* || "$p" == /usr/* || "$p" == /opt/* ]]; then
		p="\\\\wsl.localhost\\${WSL_DISTRO}${p}"
		p="${p//\//\\}"
		echo "$p"
		return
	fi
	# /mnt/c/... → C:\...
	if [[ "$p" =~ ^/mnt/([a-z])/(.*) ]]; then
		local drive="${BASH_REMATCH[1]^^}"
		local rest="${BASH_REMATCH[2]}"
		rest="${rest//\//\\}"
		echo "${drive}:\\${rest}"
		return
	fi
	# Already Windows or unknown — pass through
	echo "$p"
}

usage() {
	cat <<'EOF'
Usage: everything-search.sh find <query> [options]

Search filenames/paths across all indexed drives using Everything.

Options:
  --ext <ext>       Filter by extension (e.g., json, py, md)
  --path <path>     Scope to directory (WSL or Windows paths accepted)
  --dirs            Show directories only
  --files           Show files only
  --size            Include file sizes
  --date            Include modification dates
  --regex           Use regex matching
  -n <num>          Max results (default: 25)
  --raw             Skip path conversion (return Windows paths)
  -h, --help        Show this help

Exit codes:
  0  Results found
  1  No results
  2  Everything service not running
  3  es.exe not found
EOF
}

# --- Main ---

if [[ $# -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
	usage
	exit 0
fi

# Require "find" subcommand
if [[ "$1" != "find" ]]; then
	die "Unknown subcommand '$1'. Use: everything-search.sh find <query>" 1
fi
shift

if [[ $# -lt 1 ]]; then
	die "Missing query. Usage: everything-search.sh find <query> [options]" 1
fi

# Parse arguments
QUERY="$1"
shift

LIMIT="$DEFAULT_LIMIT"
EXT=""
SEARCH_PATH=""
DIRS_ONLY=false
FILES_ONLY=false
SHOW_SIZE=false
SHOW_DATE=false
USE_REGEX=false
RAW_OUTPUT=false

while [[ $# -gt 0 ]]; do
	case "$1" in
	--ext)
		EXT="$2"
		shift 2
		;;
	--path)
		SEARCH_PATH="$2"
		shift 2
		;;
	--dirs)
		DIRS_ONLY=true
		shift
		;;
	--files)
		FILES_ONLY=true
		shift
		;;
	--size)
		SHOW_SIZE=true
		shift
		;;
	--date)
		SHOW_DATE=true
		shift
		;;
	--regex)
		USE_REGEX=true
		shift
		;;
	-n)
		LIMIT="$2"
		shift 2
		;;
	--raw)
		RAW_OUTPUT=true
		shift
		;;
	*) die "Unknown option: $1" 1 ;;
	esac
done

# Build es.exe command
ES_ARGS=()
ES_ARGS+=("-max-results" "$LIMIT")

# Extension filter uses Everything search syntax as a separate arg
# (the -ext flag only adds an output column, it doesn't filter)
EXT_ARG=""
if [[ -n "$EXT" ]]; then
	EXT_ARG="ext:${EXT}"
fi

if [[ -n "$SEARCH_PATH" ]]; then
	local_win_path="$(wsl_to_win "$SEARCH_PATH")"
	ES_ARGS+=("-path" "$local_win_path")
fi

# /ad = directories only, /a-d = files only (es.exe DIR-style attributes)
if $DIRS_ONLY; then
	ES_ARGS+=("/ad")
fi

if $FILES_ONLY; then
	ES_ARGS+=("/a-d")
fi

# -size and -date-modified add output columns
if $SHOW_SIZE; then
	ES_ARGS+=("-size")
fi

if $SHOW_DATE; then
	ES_ARGS+=("-date-modified")
fi

if $USE_REGEX; then
	ES_ARGS+=("-regex")
fi

# Run with timeout
OUTPUT=""
CMD=("$ES_EXE" "${ES_ARGS[@]}")
[[ -n "$EXT_ARG" ]] && CMD+=("$EXT_ARG")
CMD+=("$QUERY")
if ! OUTPUT=$(timeout "${TIMEOUT_SEC}s" "${CMD[@]}" 2>&1); then
	EXIT_CODE=$?
	if [[ $EXIT_CODE -eq 124 ]]; then
		die "Timed out after ${TIMEOUT_SEC}s. Is the Everything service running?" 2
	fi
	# es.exe returns 0 even for no results — check output
	if [[ -z "$OUTPUT" ]]; then
		echo "No results found for: $QUERY"
		exit 1
	fi
fi

if [[ -z "$OUTPUT" ]]; then
	echo "No results found for: $QUERY"
	exit 1
fi

# Output results
COUNT=0
while IFS= read -r line; do
	[[ -z "$line" ]] && continue
	if $RAW_OUTPUT; then
		echo "$line"
	else
		convert_path "$line"
	fi
	COUNT=$((COUNT + 1))
done <<<"$OUTPUT"

if [[ $COUNT -eq 0 ]]; then
	echo "No results found for: $QUERY"
	exit 1
fi

echo "--- $COUNT result(s) ---"
