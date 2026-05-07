#!/usr/bin/env bash
# precommit-compliance.sh
#
# Runs a fast subset of pygeia compliance checks on staged Python files.
# Designed to be installed as `.git/hooks/pre-commit` by `/install-precommit`.
#
# Current checks (intentionally small — must complete in <2s on typical staged sets):
#   1. Repository calls in interactor code must include `partner_scope=`.
#      Pattern source: ${PYGEIA_ROOT}/docs/code-standards/partner-scope.md
#   2. (Reserved) Forbidden vocabulary per domain. Disabled until ubiquitous-language.md
#      provides a machine-checkable glossary; see Issue tracker.
#
# To extend: add a new check function and call it inside the per-file loop.
# Each check should print HUMAN-READABLE violations to stderr and append to $VIOLATIONS.
#
# Exit 0 iff there are zero violations. Otherwise exit 1 and let git block the commit.

set -euo pipefail

# Find staged python files (added/modified/copied — not deleted)
mapfile -t STAGED < <(git diff --cached --name-only --diff-filter=ACM | grep -E '\.py$' || true)

if [ "${#STAGED[@]}" -eq 0 ]; then
  exit 0
fi

VIOLATION_COUNT=0

violation() {
  local severity="$1"
  local file="$2"
  local line="$3"
  local rule="$4"
  local detail="$5"
  printf '\033[1;31m[%s]\033[0m %s:%s\n  rule: %s\n  %s\n\n' \
    "$severity" "$file" "$line" "$rule" "$detail" >&2
  VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
}

# Check 0: hardcoded secrets — fail fast, very low false-positive patterns only.
# Anything matching these almost certainly does not belong in version control.
check_hardcoded_secrets() {
  local file="$1"
  # Skip binary files defensively
  if ! grep -Iq . "$file" 2>/dev/null; then
    return 0
  fi

  # Pattern set kept tight on purpose. Add to it only with hits proven on fixtures.
  local patterns=(
    'AKIA[0-9A-Z]{16}'                                            # AWS Access Key ID
    'sk_live_[A-Za-z0-9]{16,}'                                    # Stripe live secret
    'rk_live_[A-Za-z0-9]{16,}'                                    # Stripe live restricted
    'xox[baprs]-[A-Za-z0-9-]{10,}'                                # Slack tokens
    'ghp_[A-Za-z0-9]{36,}'                                        # GitHub PAT (classic)
    'github_pat_[A-Za-z0-9_]{50,}'                                # GitHub PAT (fine-grained)
    'eyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}' # JWT
    '-----BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----'   # Private key block
    'AIza[A-Za-z0-9_-]{35}'                                       # Google API key
  )
  local pattern
  for pattern in "${patterns[@]}"; do
    local hits
    hits="$(grep -nE -- "$pattern" "$file" || true)"
    if [ -z "$hits" ]; then continue; fi
    while IFS= read -r h; do
      local lineno="${h%%:*}"
      violation "HIGH" "$file" "$lineno" \
        "security-controls-reviewer.md → 'Secrets & Credentials in Code'" \
        "Match for high-confidence secret pattern: $pattern. Move the value to your secret store; rotate it immediately if it ever reached this branch."
    done <<<"$hits"
  done
}

# Check 1: repository calls in interactors must include partner_scope=
check_partner_scope_passed() {
  local file="$1"
  # Only enforce on interactor files
  case "$file" in
    *domains/*/interactors/*) ;;
    *) return 0 ;;
  esac

  # Find lines with repository method calls that don't appear to pass partner_scope
  # This is a heuristic — multi-line calls split across lines aren't caught here
  # (the deep partner-scope-auditor agent does that during /build).
  local matches
  matches="$(grep -n -E 'repository\.(get|list|count|create|update|delete|custom_query)\(' "$file" || true)"
  if [ -z "$matches" ]; then return 0; fi

  while IFS= read -r m; do
    local lineno="${m%%:*}"
    local content="${m#*:}"
    # Look ahead a few lines for partner_scope= (multi-line call support)
    local block
    block="$(awk -v start="$lineno" 'NR>=start && NR<=start+10' "$file")"
    if ! echo "$block" | grep -q 'partner_scope='; then
      violation "HIGH" "$file" "$lineno" \
        "partner-scope.md → 'Pass scope forward'" \
        "Repository call appears to omit partner_scope=. Forward contract.partner_scope, or pass PartnerScope.unscoped explicitly with a comment justifying it."
    fi
  done <<<"$matches"
}

# Secret scanning runs on ALL staged files (not only .py)
mapfile -t STAGED_ALL < <(git diff --cached --name-only --diff-filter=ACM || true)
for f in "${STAGED_ALL[@]}"; do
  check_hardcoded_secrets "$f"
done

for f in "${STAGED[@]}"; do
  check_partner_scope_passed "$f"
done

if [ "$VIOLATION_COUNT" -gt 0 ]; then
  cat >&2 <<EOF
$VIOLATION_COUNT compliance violation(s) found in staged files.

To bypass for an emergency commit, use \`git commit --no-verify\` — but plan to fix
in a follow-up. Most violations indicate a real risk (data leak, regression).

For a deeper audit, run \`/build\` from Claude Code or invoke the partner-scope-auditor
agent directly via \`/review code\`.
EOF
  exit 1
fi

exit 0
