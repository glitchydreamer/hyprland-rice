---
name: feedback-sudo-real-terminal
description: "Never run sudo via Claude's ! bridge — surface sudo steps for the user to run in a real terminal"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3e580e21-3aa2-41e4-b07c-1d0cc9cca6b4
---

**Surface every `sudo` step for the user to run in a real terminal; never run it
through Claude's `!` bridge.**

**Why:** the `!` bridge mangles the password prompt. Three failed attempts trip
`pam_faillock` (deny=3, unlock_time=600s) and lock `sudo` for 10 minutes —
blocking real work. `su` is unaffected (no faillock in its PAM stack).

**How to apply:** when a task needs root (the `install.sh`/`nvidia-switch.sh`
system steps), write out the exact command and ask the user to run it, e.g. via
the `! <command>` prompt prefix or their own terminal. Scripts like `install.sh`
call sudo themselves, so hand those to the user too. If already locked: wait
10 min, or `su -` to root and `faillock --user <you> --reset`.

Related: fish has **no heredocs** — to write a root-owned file use
`printf '…\n' | sudo tee /path`, not `sudo tee … <<'EOF'`.
See [[feedback-maintenance-loop]].
