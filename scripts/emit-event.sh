#!/usr/bin/env bash
# emit-event.sh
#
# Append a single telemetry event to the local build metrics JSONL.
#
# Design invariants:
#   - PRIVACY: metadata only. Paths, rule citations, counts, timing, agent names.
#     NEVER file contents, NEVER patient/clinical/PII data, NEVER secrets.
#     The emitter blocks obvious PII keys at emit time as a defence-in-depth check;
#     the per-event-type allowlist is enforced by docs/telemetry-events.md.
#   - BEST-EFFORT: never blocks the harness. Any failure (missing jq, bad JSON,
#     unwritable target, missing slug) results in silent exit 0 — telemetry must
#     not be a critical path.
#   - LOCAL-ONLY (Phase B will route to a shared MCP). The on-disk format is the
#     contract; the routing is replaceable.
#
# Usage:
#   emit-event.sh <event_type> <task_slug> [json_payload]
#
# Examples:
#   emit-event.sh build.started add-patient-consent '{"scope_hash":"abc123"}'
#   emit-event.sh gate.verdict add-patient-consent '{"phase":7,"agent":"partner-scope-auditor","verdict":"pass","hi":0,"med":0,"low":2}'
#
# Output destination:
#   <repo>/.claude/state/build/.metrics/<task_slug>.jsonl

set -u  # NOT -e — failures must be silent

event_type="${1:-}"
task_slug="${2:-}"
payload="${3:-{\}}"

# Required arguments
[ -n "$event_type" ] || exit 0
[ -n "$task_slug" ] || exit 0

# Resolve working repo root (fallback: cwd)
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
metrics_dir="$repo_root/.claude/state/build/.metrics"

# Best-effort mkdir
mkdir -p "$metrics_dir" 2>/dev/null || exit 0

# Need jq to safely build the JSON line
command -v jq >/dev/null 2>&1 || exit 0

# Validate JSON payload — drop to {} if malformed.
# Note: `jq empty` (no -e) exits 0 on valid JSON, nonzero on parse error.
# Adding -e here would invert the semantic (empty produces no output → -e → nonzero).
if ! echo "$payload" | jq empty >/dev/null 2>&1; then
  payload="{}"
fi

# Privacy guard: reject payloads whose top-level keys look like PII / secrets / contents.
# This is a backstop, not the primary enforcement. The primary enforcement is
# per-event-type allowlists in docs/telemetry-events.md, applied by the caller.
disallowed_keys='content|body|diff|patient|patient_id|patient_name|email|phone|cpf|cnpj|rg|password|secret|token|api_key|access_key|private_key|jwt|raw_sql|sql|prompt|response_text'
if echo "$payload" | jq -r 'keys[]' 2>/dev/null | grep -qE "^($disallowed_keys)$"; then
  exit 0
fi

# Build the event line
ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)"
[ -n "$ts" ] || exit 0

event_line="$(jq -nc \
  --arg type "$event_type" \
  --arg slug "$task_slug" \
  --arg ts "$ts" \
  --argjson payload "$payload" \
  '{type:$type, task_slug:$slug, ts:$ts, payload:$payload}' 2>/dev/null)"

[ -n "$event_line" ] || exit 0

# Append. `>>` on a small write is atomic on local POSIX filesystems.
target="$metrics_dir/${task_slug}.jsonl"
echo "$event_line" >> "$target" 2>/dev/null || true

exit 0
