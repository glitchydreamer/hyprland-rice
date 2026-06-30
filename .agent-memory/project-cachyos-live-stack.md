---
name: project-cachyos-live-stack
description: "Live-box state — CachyOS, NVIDIA pinned 580.119.02 for Isaac, Limine bootloader, caelestia-owned files off-limits"
metadata: 
  node_type: memory
  type: project
  originSessionId: 3e580e21-3aa2-41e4-b07c-1d0cc9cca6b4
---

**Live box = CachyOS** (read `docs/cachyos/project-context.md` first when working
the live system; Arch build is kept in parity). Boot-critical constraints:

- **NVIDIA pinned at 580.119.02** (`nvidia-open-dkms` + `IgnorePkg`) — Isaac
  Sim/Lab need the validated 580 branch. Boot **`linux-cachyos-lts`** (6.18);
  `linux-cachyos` 7.0 can't build 580 (expected TTY fallback). Manage the whole
  stack **only** via `cachyos/nvidia-switch.sh` (atomic, pinned, verifies the DKMS
  build, steers Limine `default_entry`). After a downgrade,
  `nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml` is deferred to
  post-reboot — a stale CDI spec breaks `docker --gpus all`.
- **Bootloader is Limine** — steer `default_entry:`, never manage UKI, never guess
  an index.
- **Robotics stack:** Isaac Sim/Lab native on 580 + **ROS 2 Humble** container
  (`osrf/ros:humble-desktop-full`) + **MoveIt 2 Humble**, sharing a DDS domain.
  Humble (Fast DDS 2.6) matches Isaac's bundled bridge — Jazzy crashed Isaac on a
  cross-distro DDS mismatch. UDP-only transport via a Fast DDS XML profile
  (`~/.config/ros2/fastdds-udp-only.xml`) because native Isaac (UID 1000) and the
  root container can't share `/dev/shm`.
- **CachyOS-specific quirks:** duplicate cursor fixed by `misc { vrr = 0 }` (NOT a
  CPU-cursor buffer); DualSense needs no special work (stock PipeWire drives it).

**Don't edit caelestia-owned files:** `~/.config/fish/config.fish` and the hypr
base tree. Personal fish → `~/.config/fish/conf.d/dev-env.fish`; personal hypr →
`~/.config/caelestia/hypr-user.conf`.

See [[feedback-maintenance-loop]], [[feedback-sudo-real-terminal]],
[[user-profile]].
