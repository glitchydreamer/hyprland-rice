---
name: feedback-maintenance-loop
description: "Do-by-default loop — fold every fix into the scripts, update docs in the same commit, push to origin/main"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3e580e21-3aa2-41e4-b07c-1d0cc9cca6b4
---

Every fix or feature is followed — **deliberately, without being asked** — by
the full loop:

1. **Fold it into the automated scripts.** `install.sh` for system/sudo steps,
   `setup-home.sh` for home configs/launchers, `uninstall.sh` gets a matching
   component when something is *removed*. No ad-hoc `/tmp` one-offs — removals go
   through `uninstall.sh`.
2. **Make it robust.** Idempotent, self-limiting, `FAILED=()`-tracked (rolling
   release breaks things). All four scripts share one shape: no-arg numbered menu
   OR component names / `all` / `--yes` / `--dry-run`; never abort mid-run.
3. **Update the docs in the SAME commit.** The matching page under `docs/`, and
   the relevant `project-context.md` if a decision/root-cause changed. Code and
   its docs ship together. Pushing to `main` auto-redeploys the MkDocs → GitHub
   Pages site via `.github/workflows/deploy-docs.yml` — **after a push, verify the
   `deploy-docs` run succeeded** (`gh run watch`) and the live site
   <https://glitchydreamer.github.io/hyprland-rice/> returns 200, rather than
   assuming. (The repo was renamed `arch-hyprland-setup` → `hyprland-rice`; the old
   Pages URL 404s — fix any stale link that still points at it.)
4. **Update memory** (this store) when a durable, non-obvious fact changed.
5. **Commit + push to `origin/main`.** Conventional-commit messages with the
   `Co-Authored-By: Claude …` trailer.

**Why:** a clean reinstall must reproduce the *fixed* system and a clean
uninstall must leave no trace; the docs site and the live box must never drift.

**Start-of-session:** `git fetch` + check status before working (origin can be
ahead — it has caught real divergence). See [[project-cachyos-live-stack]],
[[user-profile]].
