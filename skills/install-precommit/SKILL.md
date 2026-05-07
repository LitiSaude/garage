# /install-precommit — Install the Liti compliance pre-commit hook

Installs `precommit-compliance.sh` as the working repo's `.git/hooks/pre-commit`. Idempotent: re-running detects an existing install and updates it.

## Usage

- `/install-precommit` — installs into the current working repo.
- `/install-precommit force` — overwrites any existing hook (with backup).

## What the hook does

The installed hook runs a fast subset of pygeia compliance checks on staged Python files before every `git commit`:

1. **Partner-scope passed forward** — every repository call in interactor code must include `partner_scope=`. A missed scope check is a production data leak.
2. (Reserved for future checks — see `garage/scripts/precommit-compliance.sh` for the extension point.)

The deep audit (with all six compliance auditors) runs inside `/build`. The hook is the line of defense for commits that bypass `/build`.

## Behavior

1. **Resolve garage root.** The skill needs to know where `garage/scripts/precommit-compliance.sh` lives. Use `git rev-parse --show-toplevel` from inside garage if running from there, or fall back to `dirname` resolution from the skill's own location.
2. **Verify the working repo is a git repo.** Run `git rev-parse --is-inside-work-tree`; halt if not.
3. **Locate the hooks dir.** `.git/hooks/` of the working repo (handles `git worktree` and submodules via `git rev-parse --git-path hooks`).
4. **Check for existing pre-commit hook:**
   - If absent: install.
   - If present and identical to our script: report "already installed (current version)" and exit.
   - If present and different: prompt the user. Options: backup the existing hook to `pre-commit.backup-<timestamp>` and install, OR cancel. With `force`, take the backup-and-replace path without prompting.
5. **Install:** create `.git/hooks/pre-commit` as a wrapper that calls the canonical `garage/scripts/precommit-compliance.sh`. The wrapper resolves the absolute path so the hook works even if garage is elsewhere on disk:
   ```sh
   #!/usr/bin/env bash
   exec "<absolute-path-to-garage>/scripts/precommit-compliance.sh" "$@"
   ```
6. **chmod +x** the new hook.
7. **Verify** by running the hook against an empty commit (`echo | .git/hooks/pre-commit`) — should exit 0 silently.
8. **Report** install status, the backup path (if any), and example commands to test it (`make a deliberate violation, stage it, attempt commit, expect block`).

## Anti-patterns to refuse

- Installing into a non-git directory.
- Silently overwriting an existing different hook.
- Installing without the executable bit set.
- Hardcoding `/Users/brn/...` in the wrapper — always resolve garage's absolute path at install time.

## Uninstall

To remove: `rm .git/hooks/pre-commit` (and rename any `pre-commit.backup-*` back if desired).

## Tools

- **Bash** — git commands, file copy / chmod, install / verify.
- **Read, Write** — read garage's script, write the hook wrapper.
- **Glob** — find existing backups for cleanup info.
