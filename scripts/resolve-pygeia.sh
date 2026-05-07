#!/usr/bin/env bash
# resolve-pygeia.sh
#
# Resolves the absolute path of the pygeia checkout for the current teammate.
# Prints the resolved path to stdout on success. On failure prints a clear
# explanation to stderr and exits non-zero.
#
# Resolution order:
#   1. $LITI_PYGEIA_PATH (if set and valid)
#   2. Sibling/upward search from $(pwd) for a "pygeia" directory
#   3. Persisted config at ~/.claude/liti-garage.json (key: pygeia_path)
#   4. Interactive prompt + persist (only when stdin/stderr are TTYs)

set -euo pipefail

CONFIG_PATH="${HOME}/.claude/liti-garage.json"

is_pygeia_root() {
  [ -n "${1:-}" ] && [ -d "$1" ] && [ -f "$1/docs/code-standards/principles.md" ]
}

read_persisted_path() {
  [ -f "$CONFIG_PATH" ] || return 1
  if command -v jq >/dev/null 2>&1; then
    jq -r '.pygeia_path // empty' "$CONFIG_PATH" 2>/dev/null
  else
    sed -n 's/.*"pygeia_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG_PATH" | head -1
  fi
}

write_persisted_path() {
  local path="$1"
  mkdir -p "$(dirname "$CONFIG_PATH")"
  if [ -f "$CONFIG_PATH" ] && command -v jq >/dev/null 2>&1; then
    local tmp
    tmp="$(mktemp)"
    jq --arg p "$path" '.pygeia_path = $p' "$CONFIG_PATH" >"$tmp" && mv "$tmp" "$CONFIG_PATH"
  else
    printf '{\n  "pygeia_path": "%s"\n}\n' "$path" >"$CONFIG_PATH"
  fi
}

# 1. Environment variable
if [ -n "${LITI_PYGEIA_PATH:-}" ]; then
  if is_pygeia_root "$LITI_PYGEIA_PATH"; then
    cd "$LITI_PYGEIA_PATH" && pwd
    exit 0
  fi
  echo "warn: \$LITI_PYGEIA_PATH=$LITI_PYGEIA_PATH does not look like a pygeia checkout (missing docs/code-standards/principles.md). Trying other methods." >&2
fi

# 2. Sibling/upward search from cwd
search_dir="$(pwd)"
while :; do
  candidate="$search_dir/pygeia"
  if is_pygeia_root "$candidate"; then
    cd "$candidate" && pwd
    exit 0
  fi
  parent="$(dirname "$search_dir")"
  [ "$parent" = "$search_dir" ] && break
  search_dir="$parent"
done

# 3. Persisted config
persisted="$(read_persisted_path || true)"
if [ -n "${persisted:-}" ]; then
  if is_pygeia_root "$persisted"; then
    cd "$persisted" && pwd
    exit 0
  fi
  echo "warn: $CONFIG_PATH has pygeia_path=$persisted but it is not a valid pygeia checkout. Re-prompting." >&2
fi

# 4. Prompt + persist (interactive only)
if [ ! -t 0 ] || [ ! -t 2 ]; then
  cat >&2 <<EOF
error: cannot resolve pygeia path. None of the following worked:
  1. \$LITI_PYGEIA_PATH unset or invalid
  2. No 'pygeia' directory found by walking up from $(pwd)
  3. ${CONFIG_PATH} missing or invalid

Set \$LITI_PYGEIA_PATH in your shell, or run this interactively to be prompted.
EOF
  exit 1
fi

printf 'Path to pygeia checkout: ' >&2
read -r entered
entered="${entered/#\~/$HOME}"
if ! is_pygeia_root "$entered"; then
  echo "error: $entered does not look like a pygeia checkout (missing docs/code-standards/principles.md)" >&2
  exit 1
fi
abs="$(cd "$entered" && pwd)"
write_persisted_path "$abs"
echo "$abs"
