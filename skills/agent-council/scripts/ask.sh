#!/usr/bin/env bash
# Usage: ask.sh <member-name> <prompt-file>
# Runs one CLI council member from the roster; its answer goes to stdout.
# The prompt arrives on stdin and as $PROMPT_FILE, so a roster command can use either.
set -euo pipefail

[ $# -eq 2 ] || { echo "usage: ask.sh <member-name> <prompt-file>" >&2; exit 2; }
roster="${AGENT_COUNCIL_ROSTER:-$HOME/.config/agent-council/roster.json}"
[ -f "$roster" ] || { echo "no roster at $roster; run /setup-agent-council first" >&2; exit 2; }
[ -f "$2" ] || { echo "prompt file not found: $2" >&2; exit 2; }

cmd=$(jq -er --arg n "$1" '.members[] | select(.name == $n and .kind == "cli") | .command' "$roster") \
  || { echo "no cli member named '$1' in $roster" >&2; exit 2; }

export PROMPT_FILE="$2"
# macOS has no `timeout`; coreutils installs it as `gtimeout`
t=$(command -v timeout || command -v gtimeout || true)
if [ -n "$t" ]; then
  "$t" "${AGENT_COUNCIL_TIMEOUT:-600}" bash -c "$cmd" < "$PROMPT_FILE"
else
  bash -c "$cmd" < "$PROMPT_FILE"
fi
