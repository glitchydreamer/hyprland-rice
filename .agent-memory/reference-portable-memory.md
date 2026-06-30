---
name: reference-portable-memory
description: "How agent memory travels across machines — .agent-memory/ in-repo, symlinked via scripts/agent-memory.sh link"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 3e580e21-3aa2-41e4-b07c-1d0cc9cca6b4
---

This project's agent memory is **machine- and account-agnostic**. Canonical store
is **`.agent-memory/` in the repo** (travels with `git clone`); each machine's
`~/.claude/projects/<key>/memory` is a **symlink** to it, created by
`bash scripts/agent-memory.sh link` (computes the path-encoded key from `$PWD`, so
it works for any username/clone location). So memory reads/writes go through the
repo and ride the normal commit+push — edit memory, commit, push, and it appears
on the other box after `git pull` + a one-time `link`.

**On a fresh machine/clone:** `git clone … && cd hyprland-rice && bash
scripts/agent-memory.sh link` — then MEMORY.md + all memories load normally.
**Account switch on the same machine needs nothing** — memory is keyed to the OS
user + path, not the Claude account.

Habits also travel independently via the tracked root `CLAUDE.md` and the
`docs/**/project-context.md` pages. The commit-identity email is kept OUT of the
mirrored `user-profile.md` (public repo) — recover it via `git config user.email`.
See [[feedback-maintenance-loop]] (commit+push is what syncs memory).
