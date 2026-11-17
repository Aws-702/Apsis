#!/bin/sh
# End to end test of apsis update, rollback and merge mode in a throwaway home (needs git, not root).
# Run: sh ~/.config/apsis/tests/update_test.sh

set -u
unset XDG_STATE_HOME

here=$(cd "$(dirname "$0")/.." && pwd)
UPDATE="$here/update.sh"
[ -f "$UPDATE" ] || { echo "no update.sh next to the tests"; exit 2; }

T=$(mktemp -d "${TMPDIR:-/tmp}/apsis-update-test.XXXXXX") || exit 2
trap 'rm -rf "$T"' EXIT
export GIT_CONFIG_GLOBAL="$T/gitconfig" GIT_CONFIG_NOSYSTEM=1
git config --global user.name tester
git config --global user.email tester@example.com
git config --global init.defaultBranch main
git config --global advice.detachedHead false

passed=0; failed=0
ok()   { passed=$((passed + 1)); }
bad()  { failed=$((failed + 1)); echo "FAIL $1"; }
check() { if [ "$2" = "$3" ]; then ok; else bad "$1: expected [$3] got [$2]"; fi; }
has()  { case "$2" in *"$3"*) ok ;; *) bad "$1: missing [$3] in [$2]" ;; esac; }

new_world() {
    w="$T/$1"; mkdir -p "$w/home"
    git init -q --bare "$w/remote.git"
    git clone -q "$w/remote.git" "$w/work" 2>/dev/null
    (
        cd "$w/work" || exit 1
        mkdir -p .config/apsis/migrations .config/hypr .config/app
        cp "$UPDATE" .config/apsis/update.sh
        printf '2.1.0\n' > .config/apsis/VERSION
        printf '# Changelog\n\n## 2.1.0\n- old\n' > .config/apsis/CHANGELOG.md
        printf 'base v1\n' > .config/hypr/hyprland.lua
        printf 'line1\nline2\nline3\nline4\n' > .config/app/a.txt
        git add -A; git commit -qm v1; git push -q origin main
    )
    git clone -q --bare "$w/remote.git" "$w/home/.apsis"
    g="git --git-dir=$w/home/.apsis --work-tree=$w/home"
    $g checkout -q; $g config --local status.showUntrackedFiles no
}
release_v2() {
    (
        cd "$T/$1/work" || exit 1
        printf '2.2.0\n' > .config/apsis/VERSION
        printf '# Changelog\n\n## 2.2.0\n- new things\n\n## 2.1.0\n- old\n' > .config/apsis/CHANGELOG.md
        printf 'base v2\n' > .config/hypr/hyprland.lua
        printf 'line1\nline2\nline3 upstream\nline4\n' > .config/app/a.txt
        mkdir -p .config/new; printf 'upstream file\n' > .config/new/b.txt
        cat > .config/apsis/migrations/001-x.sh <<'MIG'
#!/bin/sh
mkdir -p "$HOME/.local/state/apsis" && echo ran > "$HOME/.local/state/apsis/m001"
MIG
        git add -A; git commit -qm v2; git push -q origin main
    )
}
run() { w="$1"; shift; HOME="$T/$w/home" sh "$T/$w/home/.config/apsis/update.sh" "$@" 2>&1; }

new_world a; release_v2 a
H="$T/a/home"
printf 'line1 MINE\nline2\nline3\nline4\n' > "$H/.config/app/a.txt"
mkdir -p "$H/.config/new"; printf 'mine\n' > "$H/.config/new/b.txt"

out=$(run a update --dry-run)
has "dry run reports the update" "$out" "2.1.0 -> 2.2.0"
has "dry run shows the changelog" "$out" "new things"
has "dry run flags your edit" "$out" ".config/app/a.txt"
check "dry run left the version alone" "$(cat "$H/.config/apsis/VERSION")" "2.1.0"
check "dry run left your edit" "$(head -n 1 "$H/.config/app/a.txt")" "line1 MINE"

out=$(run a update --yes --no-packages --no-restart)
has "update says it worked" "$out" "updated to 2.2.0"
check "version is new" "$(cat "$H/.config/apsis/VERSION")" "2.2.0"
check "upstream change landed" "$(sed -n 3p "$H/.config/app/a.txt")" "line3 upstream"
check "your edit survived" "$(sed -n 1p "$H/.config/app/a.txt")" "line1 MINE"
check "the new upstream file replaced yours" "$(cat "$H/.config/new/b.txt")" "upstream file"
bk=$(find "$H/.apsis-backup" -maxdepth 1 -name 'update-*' | head -n 1)
check "your colliding file was kept" "$(cat "$bk/untracked/.config/new/b.txt" 2>/dev/null)" "mine"
if [ -f "$bk/local-changes.patch" ]; then ok; else bad "a patch of your edits was saved"; fi
check "the migration ran" "$(cat "$H/.local/state/apsis/migrations.done" 2>/dev/null)" "001-x.sh"
out=$(run a update --yes --no-packages --no-restart)
has "a second update has nothing to do" "$out" "already up to date"

out=$(echo y | run a rollback "$(basename "$bk")")
check "restore brings the old version back" "$(cat "$H/.config/apsis/VERSION")" "2.1.0"
check "restore keeps your edit" "$(sed -n 1p "$H/.config/app/a.txt")" "line1 MINE"
check "restore puts your own file back" "$(cat "$H/.config/new/b.txt" 2>/dev/null)" "mine"

new_world b; release_v2 b
H="$T/b/home"
printf 'line1\nline2\nline3 MINE\nline4\n' > "$H/.config/app/a.txt"
out=$(run b update --yes --no-packages --no-restart)
check "files still update on a conflict" "$(cat "$H/.config/apsis/VERSION")" "2.2.0"
has "a conflict is reported, not hidden" "$out" "clash"
if [ -n "$(git --git-dir="$H/.apsis" --work-tree="$H" stash list)" ]; then ok; else bad "your edit is kept in the stash"; fi

new_world c; release_v2 c
H="$T/c/home"
g="git --git-dir=$H/.apsis --work-tree=$H"
printf 'my own commit\n' > "$H/.config/app/mine.txt"
$g add .config/app/mine.txt; $g commit -qm mine
before=$($g rev-parse HEAD)
out=$(run c update --yes --no-packages --no-restart)
has "diverged history is refused" "$out" "both moved on"
check "refusing changed nothing" "$($g rev-parse HEAD)" "$before"

new_world d
H="$T/d/home"
g="git --git-dir=$H/.apsis --work-tree=$H"
printf 'MY OWN HYPRLAND CONFIG\n' > "$H/.config/hypr/hyprland.lua"
$g update-index --skip-worktree .config/hypr/hyprland.lua
mkdir -p "$H/.local/state/apsis"; : > "$H/.local/state/apsis/hypr-merge"
release_v2 d
run d update --yes --no-packages --no-restart >/dev/null
check "merge mode kept your hyprland.lua" "$(cat "$H/.config/hypr/hyprland.lua")" "MY OWN HYPRLAND CONFIG"
check "merge mode still updated the rest" "$(cat "$H/.config/apsis/VERSION")" "2.2.0"

mkdir -p "$T/bin"
printf '#!/bin/sh\necho "$*" >> "%s/notify.log"\n' "$T" > "$T/bin/notify-send"
chmod +x "$T/bin/notify-send"
PATH="$T/bin:$PATH"
tab=$(printf '\t')
new_world e
H="$T/e/home"
S="$H/.local/state/apsis/update-check"
check "newer: nothing new" "$(run e newer)" "current${tab}2.1.0${tab}2.1.0${tab}0"
release_v2 e
check "newer: within a day it doesn't look again" "$(run e newer)" "current${tab}2.1.0${tab}2.1.0${tab}0"
check "newer --now finds the new version" "$(run e newer --now)" "new${tab}2.1.0${tab}2.2.0${tab}1"
check "it says so once" "$(grep -c 'Apsis 2.2.0 is out' "$T/notify.log")" "1"
run e newer --now >/dev/null
check "and not again for the same version" "$(grep -c 'Apsis 2.2.0 is out' "$T/notify.log")" "1"
(cd "$T/e/work" && printf 'more\n' > .config/app/c.txt && git add -A && git commit -qm v2b && git push -q origin main)
check "a day later it looks by itself" "$(sed "s/^[0-9]*/1/" "$S" > "$S.x" && mv "$S.x" "$S"; run e newer)" "new${tab}2.1.0${tab}2.2.0${tab}2"
run e update --yes --no-packages --no-restart >/dev/null
check "after updating it says current" "$(run e newer | cut -f1)" "current"
git --git-dir="$H/.apsis" config remote.origin.url "$T/nowhere.git"
check "offline is said, not shouted" "$(run e newer --now | cut -f1)" "offline"
left=$(( 86400 - ($(date +%s) - $(cut -f1 "$S")) ))
if [ "$left" -gt 3500 ] && [ "$left" -le 3600 ]; then ok; else bad "offline tries again in an hour (got ${left}s)"; fi

echo "update tests: $passed passed, $failed failed"
[ "$failed" -eq 0 ]
