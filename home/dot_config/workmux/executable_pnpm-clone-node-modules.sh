#!/bin/sh
# Warm a new worktree's node_modules from the main checkout via copy-on-write
# clones, then reconcile with pnpm against this branch's lockfile. The clone
# is only a cache-warmer; pnpm repairs any drift (incl. silent purge+reinstall
# when workspace config changed). Skips warming where CoW isn't supported.
set -eu

# global workmux hook — no-op outside pnpm projects
[ -f pnpm-lock.yaml ] || exit 0

main="$(git worktree list --porcelain | sed -n '1s/^worktree //p')"

warm_darwin() {
  # clonefile(2) clones a whole directory tree in one syscall
  DEST="$PWD" MAIN="$main" python3 - <<'EOF'
import ctypes, os, subprocess
libc = ctypes.CDLL(None, use_errno=True)
main, dest = os.environ["MAIN"], os.environ["DEST"]
find = subprocess.run(
    ["find", ".", "-path", "./.claude/worktrees", "-prune", "-o",
     "-name", "node_modules", "-type", "d", "-prune", "-print"],
    cwd=main, capture_output=True, text=True).stdout
ok = 0
for rel in find.splitlines():
    rel = rel[2:]
    dst = os.path.join(dest, rel)
    if not os.path.isdir(os.path.dirname(dst)) or os.path.lexists(dst):
        continue
    if libc.clonefile(os.path.join(main, rel).encode(), dst.encode(), 0) == 0:
        ok += 1
print(f"warmed {ok} node_modules dirs from {main}")
EOF
}

warm_linux() {
  # reflink probe: without CoW a data copy would be slower than pnpm's store links
  probe="$PWD/.reflink-probe.$$"
  cp --reflink=always "$main/pnpm-lock.yaml" "$probe" 2>/dev/null || return 0
  rm -f "$probe"
  (cd "$main" && find . -path ./.claude/worktrees -prune -o -name node_modules -type d -prune -print) |
    sed 's|^\./||' | while IFS= read -r rel; do
      [ -d "$PWD/$(dirname "$rel")" ] || continue
      [ -e "$PWD/$rel" ] && continue
      cp -R --reflink=always "$main/$rel" "$PWD/$rel" 2>/dev/null || true
    done
  echo "warmed node_modules from $main (reflink)"
}

if [ -n "$main" ] && [ "$main" != "$PWD" ] && [ -d "$main/node_modules" ]; then
  case "$(uname)" in
    Darwin) warm_darwin || true ;;
    Linux)  warm_linux  || true ;;
  esac
fi

pnpm install --prefer-offline --config.confirm-modules-purge=false
