#!/usr/bin/env bash
# verify-everything.sh — SessionStart check for Everything Search plugin
# Prints a one-line status. Non-blocking (always exits 0).

# Try to find es.exe
if command -v es.exe &>/dev/null; then
	ES_EXE="$(command -v es.exe)"
elif compgen -G "/mnt/c/Users/*/AppData/Local/Microsoft/WindowsApps/es.exe" >/dev/null 2>&1; then
	ES_EXE="$(compgen -G "/mnt/c/Users/*/AppData/Local/Microsoft/WindowsApps/es.exe" | head -1)"
elif [[ -f "/mnt/c/Program Files/Everything/es.exe" ]]; then
	ES_EXE="/mnt/c/Program Files/Everything/es.exe"
else
	echo "Everything Search: WARNING — es.exe not found. Install Everything CLI: https://www.voidtools.com/"
	exit 0
fi

# Quick liveness check (search for something trivial)
if timeout 2s "$ES_EXE" -max-results 1 "desktop.ini" &>/dev/null; then
	echo "Everything Search: ready"
else
	echo "Everything Search: WARNING — es.exe found but Everything service may not be running"
fi

exit 0
