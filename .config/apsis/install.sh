#!/bin/sh
# One command install: clones Apsis as a bare repo into ~/.apsis (if it isn't there), checks it out
# over your home (files in the way go to ~/.apsis-backup, `apsis rollback install` puts them back),
# then runs setup.sh. Setup flags pass through: ... | sh -s -- --dry-run
# Edit: APSIS_REPO for another repo, APSIS_GIT_DIR for another repo folder.

main() {
    REPO=${APSIS_REPO:-https://github.com/Aws-702/Apsis.git}
    GIT_DIR=${APSIS_GIT_DIR:-$HOME/.apsis}
    BACKUP="$HOME/.apsis-backup"

    say() { printf '>> %s\n' "$*"; }
    die() { printf '!! %s\n' "$*" >&2; exit 1; }
    g() { git --git-dir="$GIT_DIR" --work-tree="$HOME" "$@"; }

    [ "$(id -u)" -ne 0 ] || die "run this as your normal user, not root"
    command -v pacman >/dev/null 2>&1 || die "this installer is for Arch based systems; see the README for other distros"
    if ! command -v git >/dev/null 2>&1; then
        say "installing git"
        sudo pacman -S --needed --noconfirm git || die "Apsis needs git"
    fi

    if [ -d "$GIT_DIR" ]; then
        say "using the Apsis repo in $GIT_DIR"
    else
        say "cloning $REPO"
        git clone --quiet --bare "$REPO" "$GIT_DIR" \
            || die "couldn't clone $REPO (offline, or the address is wrong)"
    fi
    g config --local status.showUntrackedFiles no
    g config --local remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

    if ! g checkout >/dev/null 2>&1; then
        say "moving files that are in the way to $BACKUP"
        tab=$(printf '\t')
        g checkout 2>&1 | sed -n "s/^$tab$tab*//p" | while IFS= read -r f; do
            [ -e "$HOME/$f" ] || continue
            mkdir -p "$BACKUP/$(dirname "$f")"
            mv "$HOME/$f" "$BACKUP/$f"
            printf '   %s\n' "$f"
        done
        g checkout --quiet || die "the checkout still fails; look with: git --git-dir=$GIT_DIR --work-tree=$HOME status"
    fi
    say "the files are in place"

    if ( : </dev/tty ) 2>/dev/null; then
        sh "$HOME/.config/apsis/setup.sh" "$@" </dev/tty
    else
        sh "$HOME/.config/apsis/setup.sh" "$@"
    fi
}

main "$@"
