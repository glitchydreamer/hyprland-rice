# Supply-chain security — the June 2026 AUR compromise

**Goal of this page:** understand the AUR supply-chain attack of June 2026, the
*reasoning* used to decide this rice was unaffected, and the reproducible checks
to confirm it on **either drive** (Arch and CachyOS). The lesson generalises:
when a supply chain is poisoned, the question is never "am I scared?" — it's
"was I exposed to the poisoned window, and is there persistence?"

## What happened

Between roughly **2026-06-09 and 2026-06-12**, attackers compromised the AUR and
pushed malicious build content to **~1,900–2,000 packages**. The payload was an
**infostealer** (harvests browser credentials, tokens, SSH keys) plus an **eBPF
rootkit** for kernel-level persistence, delivered via **malicious npm packages**
pulled in during the build.

Reference: <https://discuss.cachyos.org/t/aur-compromised-almost-2000-packages-affected-20260611/31040>

!!! info "Why this matters for *this* rice"
    Both builds lean on the AUR heavily — `caelestia-*`, `quickshell-git`,
    `paru`, `yay-bin`, browsers, `*-git` packages. A naive `paru -Sua` during the
    bad window is exactly the action that would have pulled a poisoned build.

## The threat model — how a supply-chain attack actually infects you

A poisoned package only hurts you if you **build/install it while it is
poisoned**. The attack is *time-boxed*: the malicious content existed in the AUR
only during the campaign window. So the decisive question is a single one:

> **Did I install or upgrade an affected AUR package between 2026-06-09 and
> 2026-06-12?**

If **no**, there is no infection path — not "we cleaned it," but the door was
never opened. If **yes**, you then check for the *persistence* the payload would
have dropped (systemd units, eBPF rootkit, poisoned npm/bun caches).

This is the same "isolate the layer" discipline from the
[troubleshooting mindset](troubleshooting-mindset.md): don't panic-reinstall,
**locate the one variable that decides exposure** and inspect it.

## Reproducible verification (run on each drive)

Three independent methods agreeing is what justifies *not* nuking the system.

### 1. Were you even exposed to the window?

`/var/log/pacman.log` is world-readable, so this needs no `sudo`. It lists every
transaction; filter to the campaign window and to AUR-helper activity:

```bash
grep -E '2026-06-(09|1[012])' /var/log/pacman.log \
  | grep -iE 'paru|yay|installed|upgraded'
```

Read the output carefully: **official-repo packages are not the AUR** and are
safe. On the Arch drive this returned a single line — `pacman -S --needed
xorg-xhost` (an `extra`-repo package, installed for the rviz fix) — and **zero**
`paru`/`yay`/AUR builds. No AUR transactions in the window ⟹ no infection path.

### 2. The official announcement checker

```bash
bash <(curl -s https://cscs.pastes.sh/raw/aurvulntest20260611.sh | psub)   # fish
# bash: bash <(curl -s https://cscs.pastes.sh/raw/aurvulntest20260611.sh)
```

Cross-references your installed foreign packages (`pacman -Qm`) against the
infected list, scoped to the campaign window.

### 3. A full indicator sweep

A community checker (`aur_check-v2.sh`) covers six vectors: installed foreign
packages, historical pacman logs, **systemd persistence**, **eBPF rootkit**,
**npm cache**, **bun cache**. Always read a downloaded script before running it.

You can also spot-check persistence by hand:

```bash
ls -la ~/.config/systemd/user/        # unexpected user units?
systemctl --user list-units --type=service | grep -vi 'caelestia\|pipewire\|wireplumber\|dbus'
```

## Verdict for this rice (recorded 2026-06-17)

- **Arch drive (`gamingsoul03-archlinux`): CLEAN.** No AUR transactions in the
  window (only `xorg-xhost`, from `extra`); all three methods clean; no
  suspicious systemd user units; npm/bun caches clean. **No reinstall.**
- **CachyOS drive:** run the three checks above after booting it to close the
  loop, then update this line.

A full reinstall is warranted only with *actual indicators of compromise* — a
confirmed rootkit, unexplained persistence, integrity/exfil evidence. Positive
evidence of **non-exposure** is the opposite of that.

## What this rice's install scripts do about it

Beyond the one-off check, the repo's `install.sh` / `uninstall.sh` (both `arch/`
and `cachyos/`) now **build nothing from the AUR by default** — the standing
policy is: if a thing has an official-repo / Flatpak / upstream-release / git
source, use that; only fall back to the AUR for items with no trustworthy
alternative, and only when you opt in.

What changed:

| Used to be AUR | Now (default, no AUR) |
|---|---|
| `anaconda` | **Miniforge** — conda-forge's official installer into `~/miniforge3` (no ToS gate, no root-owned `/opt` base) |
| `brave-bin`, `microsoft-edge-stable-bin` | **Flatpak** from Flathub (`com.brave.Browser`, `com.microsoft.Edge`) |
| `candy-icons-git`, `sweet-folders-icons-git` | **git clone** of the upstream EliverLara repos into `/usr/share/icons` |
| `weylus-community-bin` | the **official GitHub release binary** (`weylus_linux.tar.gz`) → `/usr/local/bin` |
| `fastfetch-git` | the `extra`-repo `fastfetch` (and it's a caelestia dep anyway) |

What's *irreducibly* AUR-only (no trustworthy non-AUR source) is **skipped by
default** and only built if you pass `--allow-aur`, which also makes the helper
show each PKGBUILD for review before building:

- `sweet-cursors-git` / `-hyprcursor-git` — the Sweet cursor theme has no
  maintained upstream repo to clone from.
- `claude-desktop-bin` — community repackage; no official Linux build.
- a **driver-pinned older CUDA** (`cuda-<ver>`) — only when the repo `cuda` is
  newer than the pinned 580 driver supports (preferred fix: bump the driver so
  the repo toolkit fits — no AUR needed).

```bash
bash arch/install.sh apps              # browsers via Flatpak; AUR items skipped + reported
bash arch/install.sh --allow-aur apps  # opt in: also build Sweet cursors + Claude Desktop (with review)
```

The caelestia shell stack (`caelestia-shell`, `quickshell-git`, …) is still AUR —
but that's installed by **caelestia's own upstream installer**, not by these
scripts (see the top of this page).

## Going forward — cheap habits that beat this class of attack

- **Read the PKGBUILD/diff on AUR updates.** `paru` shows it before building;
  skim for unexpected `npm`/`curl`/network calls in `prepare()`/`build()`.
- **Patch normally, then rebuild** once the AUR is cleaned:
  `sudo pacman -Syu` then `paru -Sua` (in a real terminal — see the
  [sudo/faillock note](../arch/system-maintenance.md)).
- **If ever genuinely hit:** the remediation is rotate exposed secrets (browser
  passwords, API tokens, SSH keys) *and* remove persistence — not necessarily a
  full reinstall, unless the rootkit check is positive.
