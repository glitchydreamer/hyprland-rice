---
name: feedback-no-aur-policy
description: "Standing rule — avoid AUR packages; if unavoidable, only actively-maintained trustworthy official-upstream ones"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3e580e21-3aa2-41e4-b07c-1d0cc9cca6b4
---

**Always prefer non-AUR sources.** When adding or changing a package in any of the
rice scripts, use — in order — an official repo, Flatpak (Flathub), an upstream
GitHub release binary, a git clone of the upstream theme/asset, or an official
installer (e.g. Miniforge for conda). Only fall back to the AUR when there is **no
trustworthy alternative**, and even then only for an **actively-maintained,
high-trust** package — never an obscure/low-star one.

**Why:** the June 2026 AUR compromise (~2000 poisoned packages) — see
[[project-aur-campaign-2026-06]]. The user's explicit rule: *"If possible always
avoid AUR packages. And if it's an absolute must then only use actively maintained
and official packages with good trustworthiness."*

**How to apply (already encoded in the scripts as of 2026-06-17):**
- `install.sh` (both `arch/` + `cachyos/`) builds **nothing from the AUR by
  default** and bootstraps **no** yay/paru. A new `--allow-aur` flag opts in; with
  it, the helper runs WITHOUT `--noconfirm` so the PKGBUILD is shown for review.
  The `aur()` function records skipped items in `AUR_SKIPPED` and reports them.
- Repointed: `anaconda`→Miniforge, browsers→Flatpak (`com.brave.Browser`,
  `com.microsoft.Edge`), candy/Sweet icons→git clone of EliverLara repos,
  weylus→GitHub release binary (`/usr/local/bin/weylus`). Component `aurapps`→`apps`.
- Irreducibly AUR-only, gated behind `--allow-aur`: `sweet-cursors-git`(+hyprcursor),
  `claude-desktop-bin`, a driver-pinned `cuda-<ver>` (prefer bumping the driver so
  the repo `cuda` fits — no AUR).
- caelestia's own AUR deps (`caelestia-shell`, `quickshell-git`, `fastfetch-git`)
  are out of scope — caelestia's upstream installer pulls them, not our scripts.

Follows the same maintenance discipline as [[feedback-maintenance-loop]].
