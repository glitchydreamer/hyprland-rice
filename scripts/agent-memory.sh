#!/usr/bin/env bash
# ============================================================================
# agent-memory.sh — make the Claude Code agent's memory MACHINE-agnostic.
#
# The agent's persistent memory normally lives OUTSIDE the repo, under
#   ~/.claude/projects/<project-key>/memory/
# where <project-key> is this checkout's ABSOLUTE PATH with every "/" turned into
# "-" (e.g. -home-gamingsoul03-Documents-hyprland-rice). Two consequences:
#   • it is NOT carried by `git clone` (it's under ~/.claude, not the repo), and
#   • a different machine / username / clone path computes a DIFFERENT key and
#     looks in a different, empty folder.
# So a fresh PC would get all the code + docs but none of the agent's memory.
#
# This script closes that gap. The repo's `.agent-memory/` is the CANONICAL store
# (it travels with the clone); `link` points THIS machine's per-key memory dir at
# it via a symlink, so reads/writes go through the repo and ride the normal
# commit+push. Account switches on the same machine never needed this — memory is
# keyed to the OS user + path, not the Claude account — but a NEW machine does:
#
#   git clone … && cd hyprland-rice
#   bash scripts/agent-memory.sh link      # wire ~/.claude → .agent-memory (once)
#
# Subcommands:  link (default) | status | unlink | --dry-run | -h
#   link    migrate any existing per-key memory into .agent-memory, then symlink.
#   status  show the computed key, the target, and whether it's wired.
#   unlink  replace the symlink with a real, independent copy (decouple this box).
#
# Idempotent and path/user-agnostic: re-running `link` is safe; it works for any
# username or clone location because it computes the key from $PWD at runtime.
# ============================================================================
set -uo pipefail

DRY_RUN=0
CMD=""
FAILED=()
say() { echo -e "$*"; }

for arg in "$@"; do
    case "$arg" in
        --dry-run)        DRY_RUN=1 ;;
        link|status|unlink) CMD="$arg" ;;
        -h|--help)
            say "usage: agent-memory.sh [--dry-run] [link|status|unlink]"
            say "  link    (default) symlink ~/.claude memory for THIS machine -> ./.agent-memory"
            say "  status  show the project key + wiring state"
            say "  unlink  decouple: turn the symlink back into a real copy"
            exit 0 ;;
        *) say "Unknown arg '$arg' (expected link|status|unlink|--dry-run)."; exit 1 ;;
    esac
done
[ -n "$CMD" ] || CMD="link"

# Resolve the repo root (where this script lives, one level up) so the canonical
# store is found regardless of the cwd the user invoked us from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$REPO_ROOT/.agent-memory"

# The project key Claude Code derives: the repo's absolute path, "/" -> "-".
KEY="$(printf '%s' "$REPO_ROOT" | sed 's:/:-:g')"
DEST="$HOME/.claude/projects/$KEY/memory"

say "repo        : $REPO_ROOT"
say "project key : $KEY"
say "canonical   : $SRC"
say "machine dir : $DEST"
hr() { echo "------------------------------------------------------------"; }
hr

case "$CMD" in
  status)
    [ -d "$SRC" ] && say "canonical .agent-memory/: present ($(find "$SRC" -maxdepth 1 -name '*.md' | wc -l) files)" \
                  || say "canonical .agent-memory/: MISSING"
    if [ -L "$DEST" ]; then
        say "machine dir: SYMLINK -> $(readlink "$DEST")"
        [ "$(readlink "$DEST")" = "$SRC" ] && say "state: WIRED ✓" || say "state: symlinked ELSEWHERE (run 'link' to fix)"
    elif [ -d "$DEST" ]; then
        say "machine dir: real directory (NOT wired — run 'link' to make memory portable)"
    else
        say "machine dir: absent (run 'link' to create the symlink)"
    fi
    ;;

  link)
    if [ ! -d "$SRC" ]; then
        say "!! $SRC does not exist — are you in the repo? Aborting."; exit 1
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
        say "[dry-run] mkdir -p $(dirname "$DEST")"
        [ -d "$DEST" ] && [ ! -L "$DEST" ] && say "[dry-run] migrate files from $DEST into $SRC, back up $DEST -> $DEST.bak.<ts>"
        say "[dry-run] ln -sfn $SRC $DEST"
        exit 0
    fi
    mkdir -p "$(dirname "$DEST")" || FAILED+=("mkdir-parent")
    if [ -L "$DEST" ]; then
        ln -sfn "$SRC" "$DEST" && say "re-pointed existing symlink -> $SRC ✓"
    elif [ -d "$DEST" ]; then
        # Real dir with possibly-newer local memory: migrate anything not already
        # in the canonical store, then back the dir up and replace it with a link.
        local_migrated=0
        for f in "$DEST"/* "$DEST"/.[!.]*; do
            [ -e "$f" ] || continue
            b="$(basename "$f")"
            if [ ! -e "$SRC/$b" ]; then cp -a "$f" "$SRC/" && local_migrated=$((local_migrated+1)); fi
        done
        [ "$local_migrated" -gt 0 ] && say "migrated $local_migrated file(s) from the machine dir into .agent-memory/"
        bak="$DEST.bak.$(date +%s)"
        mv "$DEST" "$bak" && say "backed up the old machine dir -> $bak"
        ln -sfn "$SRC" "$DEST" && say "linked $DEST -> $SRC ✓"
    else
        ln -sfn "$SRC" "$DEST" && say "linked $DEST -> $SRC ✓"
    fi
    say ""
    say "Done. The agent's memory for this machine now reads/writes .agent-memory/,"
    say "so it travels with the repo. Commit + push to sync it to your other boxes."
    ;;

  unlink)
    if [ "$DRY_RUN" -eq 1 ]; then
        [ -L "$DEST" ] && say "[dry-run] rm symlink $DEST; cp -a $SRC $DEST (decouple)" \
                       || say "[dry-run] nothing to unlink ($DEST is not a symlink)"
        exit 0
    fi
    if [ -L "$DEST" ]; then
        rm -f "$DEST" && cp -a "$SRC" "$DEST" \
            && say "decoupled: $DEST is now a real, independent copy (edits no longer hit the repo)." \
            || FAILED+=("unlink")
    else
        say "$DEST is not a symlink — nothing to do."
    fi
    ;;
esac

if [ "${#FAILED[@]}" -gt 0 ]; then
    say ""; say "Completed with issues: ${FAILED[*]}"; exit 1
fi
