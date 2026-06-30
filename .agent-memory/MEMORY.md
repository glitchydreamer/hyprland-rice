# Memory index — hyprland-rice

- [User profile](user-profile.md) — robotics/ML dev, CachyOS live box, ex-Ubuntu, fish, git as glitchydreamer
- [Sudo via real terminal](feedback-sudo-real-terminal.md) — never use the `!` bridge for sudo (pam_faillock 10-min lock); surface steps to the user
- [Maintenance loop](feedback-maintenance-loop.md) — fix → fold into scripts → update docs in same commit → update memory → push to origin/main
- [CachyOS live stack](project-cachyos-live-stack.md) — NVIDIA pinned 580.119.02, Limine, ROS 2 Humble + MoveIt 2 + Isaac, caelestia files off-limits
- [AUR campaign June 2026](project-aur-campaign-2026-06.md) — supply-chain compromise; Arch box verified CLEAN (no reinstall); CachyOS still to confirm; checks in docs/common
- [No-AUR policy](feedback-no-aur-policy.md) — avoid AUR; scripts build nothing from AUR by default (--allow-aur opt-in); repointed to repo/Flatpak/Miniforge/upstream
- [Portable memory](reference-portable-memory.md) — memory is in-repo at .agent-memory/, symlinked per-machine via `scripts/agent-memory.sh link`; travels via git, account-agnostic
