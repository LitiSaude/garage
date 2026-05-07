#!/usr/bin/env bash
# validate-gate-progression.sh — Claude Code PreToolUse hook
#
# Purpose: turn /build's phase pipeline from advisory prose into a hard,
# deterministic block. The orchestrator MUST advance phases one at a time.
# Forward jumps of more than 1 are denied — preventing accidental gate skips
# (e.g., jumping straight from Phase 3 Plan to Phase 7 Self-review without
# Phases 4 (scaffold), 5 (TDD-RED), 6 (implement)).
#
# Allowed transitions (in `phase` field of state file):
#   - First-time creation (target file did not previously exist)
#   - phase = previous_phase                  (idempotent re-write of same state)
#   - phase = previous_phase + 1              (forward by one)
#   - phase < previous_phase                  (backward — re-running an earlier phase)
#
# Denied:
#   - phase forward jump > 1 (skip-gate)
#
# Hook contract (Claude Code):
#   stdin: {"tool_name":"Write|Edit|MultiEdit", "tool_input":{...}}
#   stdout (deny): {"permissionDecision":"deny","permissionDecisionReason":"..."}
#   stdout (allow): empty (or omitted)
#   exit code: 0 always — failure-open by design (telemetry/state writes are too
#              critical to block on hook bugs; the orchestrator's phase
#              progression is still observable in state files).
#
# Best-effort: any inability to parse → allow. Conservative on ambiguous input.

set -uo pipefail

input="$(cat 2>/dev/null || true)"
[ -n "$input" ] || exit 0

# jq required for parsing
command -v jq >/dev/null 2>&1 || exit 0

tool_name="$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null)"
file_path="$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"

case "$tool_name" in
  Write|Edit|MultiEdit) ;;
  *) exit 0 ;;
esac

# Only inspect /build state files: <repo>/.claude/state/build/<slug>.json
# Exclude managed subdirectories (.archived/.completed/.metrics/).
case "$file_path" in
  */.claude/state/build/*.json) ;;
  *) exit 0 ;;
esac
case "$file_path" in
  */.archived/*|*/.completed/*|*/.metrics/*) exit 0 ;;
esac

# Extract the proposed phase from the tool input
proposed_phase=""
case "$tool_name" in
  Write)
    content="$(echo "$input" | jq -r '.tool_input.content // empty' 2>/dev/null)"
    [ -n "$content" ] || exit 0
    proposed_phase="$(echo "$content" | jq -r '.phase // empty' 2>/dev/null || true)"
    ;;
  Edit|MultiEdit)
    # Best-effort: scan new_string(s) for a "phase":N pattern.
    new_str="$(echo "$input" | jq -r '.tool_input.new_string // ((.tool_input.edits // []) | map(.new_string) | join(" ")) // empty' 2>/dev/null)"
    proposed_phase="$(echo "$new_str" | sed -n 's/.*"phase"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -1)"
    ;;
esac

# Couldn't determine the proposed phase → allow (we don't block on what we can't reason about)
[ -n "$proposed_phase" ] || exit 0
# Reject non-numeric defensively
case "$proposed_phase" in
  ''|*[!0-9]*) exit 0 ;;
esac

# Read existing phase (if file exists)
prev_phase=""
if [ -f "$file_path" ]; then
  prev_phase="$(jq -r '.phase // empty' "$file_path" 2>/dev/null || true)"
fi
case "$prev_phase" in
  ''|*[!0-9]*) prev_phase="" ;;
esac

# First creation — allow
[ -n "$prev_phase" ] || exit 0

# Same, +1, or backward — allow
delta=$((proposed_phase - prev_phase))
if [ "$delta" -le 1 ]; then
  exit 0
fi

# Block — forward jump > 1
reason="Gate progression blocked on $(basename "$file_path"): proposed phase ${prev_phase} → ${proposed_phase} (delta +${delta}). The /build orchestrator must advance one phase at a time; skipping gates loses pygeia compliance enforcement. To resume from an earlier phase, write a phase value <= ${prev_phase}. To advance, complete the intermediate phases first. State file: ${file_path}"

jq -nc \
  --arg reason "$reason" \
  '{permissionDecision:"deny", permissionDecisionReason:$reason}'

exit 0
