#!/bin/sh
# Tests install.sh against a local fake repo in a throwaway home: clone, files in the way, setup flags, a second run.
# Run: sh ~/.config/apsis/tests/install_test.sh

set -u
here=$(cd "$(dirname "$0")/.." && pwd)
INSTALL="$here/install.sh"
[ "$(id -u)" -ne 0 ] || { echo "run it as your normal user"; exit 2; }
T=$(mktemp -d "${TMPDIR:-/tmp}/apsis-install-test.XXXXXX") || exit 2
trap 'rm -rf "$T"' EXIT
export GIT_CONFIG_GLOBAL="$T/gitconfig" GIT_CONFIG_NOSYSTEM=1
git config --global user.name tester
git config --global user.email tester@example.com
git config --global init.defaultBranch main

passed=0; failed=0
ok()   { passed=$((passed + 1)); }
bad()  { failed=$((failed + 1)); echo "FAIL $1"; }
check() { if [ "$2" = "$3" ]; then ok; else bad "$1: expected [$3] got [$2]"; fi; }

mkdir -p "$T/bin" "$T/home/.config/fish"
printf '#!/bin/sh\nexit 0\n' > "$T/bin/pacman"; chmod +x "$T/bin/pacman"
git init -q --bare "$T/remote.git"
git clone -q "$T/remote.git" "$T/work" 2>/dev/null
(
    cd "$T/work" || exit 1
    mkdir -p .config/apsis .config/fish
    cp "$INSTALL" .config/apsis/install.sh
    printf '#!/bin/sh\necho "setup $*" >> "$HOME/setup.log"\n' > .config/apsis/setup.sh
    printf 'apsis fish\n' > .config/fish/config.fish
    printf 'readme\n' > README.md
    git add -A; git commit -qm v1; git push -q origin main
)
printf 'my own fish\n' > "$T/home/.config/fish/config.fish"
H="$T/home"
run() { HOME="$H" PATH="$T/bin:$PATH" APSIS_REPO="$T/remote.git" sh -s -- "$@" < "$INSTALL" 2>&1; }

out=$(run --dry-run)
check "the repo is cloned" "$(git --git-dir="$H/.apsis" rev-parse --is-bare-repository)" "true"
check "Apsis's file is checked out" "$(cat "$H/.config/fish/config.fish")" "apsis fish"
check "yours was moved aside" "$(cat "$H/.apsis-backup/.config/fish/config.fish")" "my own fish"
check "setup ran with the flags" "$(cat "$H/setup.log")" "setup --dry-run"
check "untracked files stay quiet" "$(git --git-dir="$H/.apsis" config status.showUntrackedFiles)" "no"
check "updates can fetch" "$(git --git-dir="$H/.apsis" config remote.origin.fetch)" "+refs/heads/*:refs/remotes/origin/*"
out=$(run)
case "$out" in *"using the Apsis repo"*) ok ;; *) bad "a second run reuses the repo: $out" ;; esac
check "a second run runs setup again" "$(wc -l < "$H/setup.log" | tr -d ' ')" "2"
check "and leaves the backup alone" "$(cat "$H/.apsis-backup/.config/fish/config.fish")" "my own fish"
out=$(HOME="$T/h2" PATH="$T/bin:$PATH" APSIS_REPO="$T/nowhere.git" sh "$INSTALL" 2>&1)
case "$out" in *"couldn't clone"*) ok ;; *) bad "a bad repo says so: $out" ;; esac

echo "install tests: $passed passed, $failed failed"
[ "$failed" -eq 0 ]
