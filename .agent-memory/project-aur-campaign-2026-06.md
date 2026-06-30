---
name: project-aur-campaign-2026-06
description: "June 2026 AUR supply-chain compromise — Arch box verified CLEAN, no reinstall; CachyOS still to confirm"
metadata: 
  node_type: memory
  type: project
  originSessionId: 3e580e21-3aa2-41e4-b07c-1d0cc9cca6b4
---

The **June 2026 AUR compromise** (~2000 packages poisoned 2026-06-09→06-12;
infostealer + eBPF rootkit via malicious npm packages) prompted a "should I nuke
both drives?" scare. Verdict: **no reinstall.**

**Arch drive (`gamingsoul03-archlinux`): CLEAN** — checked 2026-06-17. Decisive
evidence: `/var/log/pacman.log` shows the *only* transaction in the campaign
window was `pacman -S --needed xorg-xhost` (an `extra`-repo package, not AUR) —
**zero paru/yay/AUR builds in the window**, so no infection path. Corroborated by
the official announcement checker, the community `aur_check-v2.sh` (6 vectors:
installed pkgs, logs, systemd, eBPF, npm/bun caches), and no suspicious systemd
user units. Three independent methods, all clean.

**CachyOS drive: still to confirm** — boot it and run the same three checks
(see the docs page), then update this.

**Why:** a full reinstall is only justified by real indicators of compromise; we
had positive evidence of *non-exposure* (never built an AUR pkg in the poisoned
window). The reusable reasoning + reproducible checks now live in the repo at
`docs/common/aur-supply-chain-2026-06.md` (so they sync to the CachyOS box via
git — the memory store does **not** sync across drives, the repo does).

**How to apply:** for any supply-chain scare, first ask "was I exposed to the
poisoned window?" via `grep -E '2026-06-(09|1[012])' /var/log/pacman.log | grep
-iE 'paru|yay|installed|upgraded'`, then check persistence — don't panic-reinstall.
See [[feedback-maintenance-loop]], [[project-cachyos-live-stack]].
