#!/bin/sh
# Apsis update, rollback and version. The fish function runs this:
#   apsis update               fetch, show what changes, ask, then update
#   apsis update --dry-run     only show what would change; touch nothing
#   apsis update --yes         don't ask
#   apsis update --no-packages don't touch packages or system files
#   apsis update --no-restart  don't restart the shell or reload Hyprland after
#   apsis rollback              list the backups an update made
#   apsis rollback NAME         roll back to how things were before that update
#   apsis rollback install      put back the files your install moved aside
#   apsis version               the installed version
#   apsis newer [--now]         is a newer Apsis on the repo? (looks at most once a day)
# Edit: BACKUPS for where backups go.

GIT_DIR="${APSIS_GIT_DIR:-$HOME/.apsis}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/apsis"
BACKUPS="$HOME/.apsis-backup"
APSIS_DIR="$HOME/.config/apsis"
VERSION_PATH=".config/apsis/VERSION"
CHANGELOG_PATH=".config/apsis/CHANGELOG.md"
HYPR_PATH=".config/hypr/hyprland.lua"

g() { git --git-dir="$GIT_DIR" --work-tree="$HOME" "$@"; }
say()  { printf '>> %s\n' "$*"; }
note() { printf '   %s\n' "$*"; }
die()  { printf '!! %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] && die "run this as your normal user, not root"
command -v git >/dev/null 2>&1 || die "git is missing"
[ -d "$GIT_DIR" ] || die "no Apsis repo at $GIT_DIR (see the README's Install section)"

version_at() { g show "$1:$VERSION_PATH" 2>/dev/null | tr -d '[:space:]' | grep . || echo unknown; }

run_migrations() {
    dir="$APSIS_DIR/migrations"
    done_file="$STATE/migrations.done"
    mkdir -p "$STATE"
    touch "$done_file"
    ran=0
    for m in "$dir"/[0-9]*.sh; do
        [ -f "$m" ] || continue
        name=$(basename "$m")
        grep -qxF "$name" "$done_file" && continue
        say "migration $name"
        if sh "$m"; then
            printf '%s\n' "$name" >> "$done_file"
            ran=$((ran + 1))
        else
            note "$name failed. Nothing after it ran. Fix the cause and run: apsis update"
            return 1
        fi
    done
    [ "$ran" -gt 0 ] && note "$ran migration(s) done"
    return 0
}

record() {
    mkdir -p "$STATE"
    printf '%s\t%s\t%s\t%s\t%s\n' "${5:-$(date +%s)}" "$1" "$2" "$3" "$4" > "$STATE/update-check"
}

quiet_fetch() {
    t=""
    command -v timeout >/dev/null 2>&1 && t="timeout 90"
    GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=true SSH_ASKPASS=true \
        GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=10" \
        $t git --git-dir="$GIT_DIR" fetch --quiet origin 2>/dev/null
}

cmd_newer() {
    f="$STATE/update-check"
    every=${APSIS_CHECK_EVERY:-86400}
    last=$(cut -f1 "$f" 2>/dev/null)
    age=$(( $(date +%s) - ${last:-0} ))
    if [ "${1:-}" = "--now" ] || [ ! -s "$f" ] || [ "$age" -ge "$every" ]; then
        cur=$(g rev-parse HEAD)
        v=$(version_at HEAD)
        if ! g config --get remote.origin.url >/dev/null 2>&1; then
            record none "$v" "$v" 0
        else
            g config --get remote.origin.fetch >/dev/null 2>&1 \
                || g config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
            branch=$(g symbolic-ref --short -q HEAD || echo main)
            if ! quiet_fetch; then
                record offline "$v" "" 0 "$(( $(date +%s) - every + 3600 ))"
            else
                new=$(g rev-parse -q --verify "origin/$branch")
                if [ -z "$new" ] || [ "$cur" = "$new" ]; then
                    record current "$v" "$v" 0
                elif g merge-base --is-ancestor "$cur" "$new"; then
                    nv=$(version_at "$new")
                    record new "$v" "$nv" "$(g rev-list --count "$cur..$new")"
                    if [ "$(cat "$STATE/update-notified" 2>/dev/null)" != "$new" ]; then
                        printf '%s\n' "$new" > "$STATE/update-notified"
                        command -v notify-send >/dev/null 2>&1 \
                            && notify-send -a Apsis "Apsis $nv is out" "You have $v. Open Updates on the phone to update." 2>/dev/null
                    fi
                else
                    record ahead "$v" "$v" 0
                fi
            fi
        fi
    fi
    cut -f2- "$f"
}

restart_shell() {
    command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1 || return 0
    command -v qs >/dev/null 2>&1 || return 0
    say "reloading Hyprland and restarting the shell"
    hyprctl reload >/dev/null 2>&1

    qs kill >/dev/null 2>&1
    sleep 1
    w="$HOME/.config/hypr/scripts/apsis-shell.sh"
    if [ -x "$w" ]; then "$w" start -d >/dev/null 2>&1; else qs -n -d >/dev/null 2>&1; fi \
        || note "the shell didn't start; run: qs -n -d"
}

cmd_update() {
    dry=0; yes=0; pkgs=1; restart=1
    for a in "$@"; do
        case "$a" in
            --dry-run) dry=1 ;;
            --yes|-y) yes=1 ;;
            --no-packages) pkgs=0 ;;
            --no-restart) restart=0 ;;
            *) die "unknown option: $a (see: apsis update --help)" ;;
        esac
    done

    remote=origin
    g config --get "remote.$remote.url" >/dev/null 2>&1 || die "the repo has no '$remote' remote"

    g config --get "remote.$remote.fetch" >/dev/null 2>&1 \
        || g config "remote.$remote.fetch" "+refs/heads/*:refs/remotes/$remote/*"

    branch=$(g symbolic-ref --short -q HEAD || echo main)
    say "checking for updates ($remote/$branch)"
    g fetch --quiet "$remote" || die "couldn't reach the remote (offline, or its address changed: apsis remote -v)"
    target="$remote/$branch"
    g rev-parse --verify -q "$target" >/dev/null || die "$target doesn't exist on the remote"

    cur=$(g rev-parse HEAD)
    new=$(g rev-parse "$target")

    if [ "$cur" = "$new" ]; then
        say "already up to date ($(version_at HEAD))"
        record current "$(version_at HEAD)" "$(version_at HEAD)" 0
        [ "$dry" -eq 1 ] && return 0
        run_migrations
        return $?
    fi

    if ! g merge-base --is-ancestor "$cur" "$new"; then
        ahead=$(g rev-list --count "$new..$cur")
        behind=$(g rev-list --count "$cur..$new")
        die "your repo and $target have both moved on ($ahead of yours, $behind new). I won't merge for you. Look first with: apsis log --oneline --graph --all, then rebase (apsis rebase $target) or merge (apsis merge $target) yourself, and run apsis update again."
    fi

    oldv=$(version_at "$cur"); newv=$(version_at "$new")
    count=$(g rev-list --count "$cur..$new")
    say "an update is waiting: $oldv -> $newv ($count commit(s))"
    echo
    g log --no-decorate --format='   %h  %s' "$cur..$new" | head -n 25
    [ "$count" -gt 25 ] && note "... and $((count - 25)) more"

    cl=$(g diff "$cur" "$new" -- "$CHANGELOG_PATH" 2>/dev/null | grep '^+' | grep -v '^+++' | cut -c2-)
    if [ -n "$cl" ]; then
        echo; say "what's new"
        printf '%s\n' "$cl" | sed 's/^/   /' | head -n 40
    fi

    changed=$(g diff --name-only "$cur" "$new")
    echo; say "$(printf '%s\n' "$changed" | wc -l | tr -d ' ') file(s) change"
    printf '%s\n' "$changed" | sed 's/^/   /' | head -n 20
    [ "$(printf '%s\n' "$changed" | wc -l)" -gt 20 ] && note "..."

    mine=$(g diff --name-only HEAD)
    clash=""
    for f in $mine; do
        printf '%s\n' "$changed" | grep -qxF "$f" && clash="$clash $f"
    done
    if [ -n "$clash" ]; then
        echo; say "you have edited files the update also changes:"
        for f in $clash; do note "$f"; done
        note "They are set aside as a patch and re-applied after the update."
    fi

    collide=""
    for f in $(g diff --name-only --diff-filter=A "$cur" "$new"); do
        [ -e "$HOME/$f" ] && collide="$collide $f"
    done
    if [ -n "$collide" ]; then
        echo; say "these files already exist on your machine and will be moved to the backup:"
        for f in $collide; do note "$f"; done
    fi

    if printf '%s\n' "$changed" | grep -q '^\.config/apsis/setup\.sh$\|^\.config/apsis/sddm/'; then
        echo; note "The system side changed too (packages, the SDDM theme or its helper). It will ask for sudo."
    fi

    if [ "$dry" -eq 1 ]; then
        echo; say "dry run: nothing was changed"
        return 0
    fi

    if [ "$yes" -eq 0 ]; then
        echo
        printf 'Update now? [y/N] '
        read -r ans
        case "$ans" in y|Y|yes|YES) ;; *) say "left as it was"; return 0 ;; esac
    fi

    stamp=$(date +%Y%m%d-%H%M%S)
    bk="$BACKUPS/update-$stamp"
    mkdir -p "$bk/files" "$bk/untracked" || die "can't create $bk"
    printf '%s\n' "$cur" > "$bk/FROM"
    printf '%s\n' "$new" > "$bk/TO"
    printf '%s -> %s\n' "$oldv" "$newv" > "$bk/VERSIONS"
    for f in $changed; do
        case " $collide " in *" $f "*) continue ;; esac
        if [ -e "$HOME/$f" ]; then
            mkdir -p "$bk/files/$(dirname "$f")"
            cp -p "$HOME/$f" "$bk/files/$f" 2>/dev/null
        fi
    done
    g diff HEAD > "$bk/local-changes.patch" 2>/dev/null
    [ -s "$bk/local-changes.patch" ] || rm -f "$bk/local-changes.patch"
    for f in $collide; do
        mkdir -p "$bk/untracked/$(dirname "$f")"
        mv "$HOME/$f" "$bk/untracked/$f"
    done
    say "backup: $bk"

    mykept=""
    if [ -f "$STATE/hypr-merge" ] && [ -f "$HOME/$HYPR_PATH" ]; then
        cp -p "$HOME/$HYPR_PATH" "$bk/hyprland.lua.mine"
        g update-index --no-skip-worktree "$HYPR_PATH" 2>/dev/null
        g checkout -- "$HYPR_PATH" 2>/dev/null
        mykept="$bk/hyprland.lua.mine"
        clash=$(printf '%s\n' "$clash" | tr ' ' '\n' | grep -vxF "$HYPR_PATH" | tr '\n' ' ')
    fi

    stashed=0
    if [ -n "$clash" ]; then
        if g stash push --quiet -m "apsis update $stamp"; then stashed=1
        else die "couldn't set your edits aside. Nothing was changed. Your files are copied in $bk"; fi
    fi

    if ! g merge --ff-only --quiet "$target" >/dev/null 2>&1; then
        [ "$stashed" -eq 1 ] && g stash pop --quiet >/dev/null 2>&1
        die "the update didn't apply. Nothing was changed (copies are in $bk)."
    fi
    say "files updated to $newv"

    if [ -n "$mykept" ]; then
        cp -p "$mykept" "$HOME/$HYPR_PATH"
        g update-index --skip-worktree "$HYPR_PATH" 2>/dev/null
        note "kept your own hyprland.lua (merge mode)"
    fi

    if [ "$stashed" -eq 1 ]; then
        if g stash pop --quiet >/dev/null 2>&1; then
            note "your edits are back on top of the new files"
        else
            note "your edits clash with the update. They are safe: run 'apsis stash show -p' to see them,"
            note "fix the marked files, then 'apsis stash drop'. A copy is in $bk/local-changes.patch."
        fi
    fi

    mkdir -p "$STATE" && printf '%s\n' "$bk" > "$STATE/last-update"

    if [ "$pkgs" -eq 1 ] && [ -f "$APSIS_DIR/setup.sh" ] && command -v pacman >/dev/null 2>&1; then
        say "checking packages and system files"
        sh "$APSIS_DIR/setup.sh" --update --yes || note "setup reported problems; run: sh ~/.config/apsis/setup.sh --check"
    fi

    run_migrations || note "migrations stopped early (see above)"

    [ "$restart" -eq 1 ] && restart_shell

    echo
    say "updated to $newv"
    record current "$newv" "$newv" 0
    note "something wrong? roll back with: apsis rollback $(basename "$bk")"
    note "check everything with:        apsis doctor"
}

cmd_restore() {
    what="${1:-list}"
    case "$what" in
        list)
            found=0
            for d in $(find "$BACKUPS" -maxdepth 1 -type d -name 'update-*' 2>/dev/null | sort -r); do
                found=1
                printf '   %-22s %s\n' "$(basename "$d")" "$(cat "$d/VERSIONS" 2>/dev/null)"
            done
            [ -d "$BACKUPS/.config" ] && { found=1; printf '   %-22s %s\n' install "the files your install moved aside"; }
            [ "$found" -eq 1 ] || say "no backups yet"
            [ "$found" -eq 1 ] && note "roll back with: apsis rollback NAME"
            ;;
        install)
            [ -d "$BACKUPS/.config" ] || die "there is no install backup in $BACKUPS"
            say "this copies the files your install moved aside back over Apsis's"
            printf 'Continue? [y/N] '; read -r ans
            case "$ans" in y|Y|yes) ;; *) say "left as it was"; return 0 ;; esac
            stamp=$(date +%Y%m%d-%H%M%S)
            keep="$BACKUPS/before-install-restore-$stamp"
            ( cd "$BACKUPS" && find . -path ./update-\* -prune -o -path ./before-install-restore-\* -prune -o -type f -print ) | while IFS= read -r f; do
                f=${f#./}
                if [ -e "$HOME/$f" ]; then mkdir -p "$keep/$(dirname "$f")"; cp -p "$HOME/$f" "$keep/$f"; fi
                mkdir -p "$HOME/$(dirname "$f")"; cp -p "$BACKUPS/$f" "$HOME/$f"
            done
            say "restored. What was there before is in $keep"
            ;;
        *)
            bk="$BACKUPS/$what"
            [ -d "$bk" ] || bk="$BACKUPS/update-$what"
            [ -f "$bk/FROM" ] || die "no such backup: $what (see: apsis rollback)"
            from=$(cat "$bk/FROM")
            g cat-file -e "$from^{commit}" 2>/dev/null || die "the commit this backup came from is gone from the repo"
            say "roll back to $(sed 's/ -> .*//' "$bk/VERSIONS") ($(printf '%s' "$from" | cut -c1-8))"
            note "Files Apsis tracks go back to how they were. Packages stay installed."
            note "Edits you had before that update are re-applied from its patch."
            printf 'Continue? [y/N] '; read -r ans
            case "$ans" in y|Y|yes) ;; *) say "left as it was"; return 0 ;; esac
            g reset --hard --quiet "$from" || die "the rollback failed"
            if [ -f "$bk/local-changes.patch" ]; then
                if ( cd "$HOME" && git --git-dir="$GIT_DIR" --work-tree="$HOME" apply --whitespace=nowarn "$bk/local-changes.patch" ) 2>/dev/null; then
                    note "your edits are back"
                else
                    note "couldn't re-apply your edits; the patch is $bk/local-changes.patch"
                fi
            fi

            if [ -d "$bk/untracked" ]; then
                ( cd "$bk/untracked" && find . -type f -print ) | while IFS= read -r f; do
                    f=${f#./}
                    [ -e "$HOME/$f" ] || { mkdir -p "$HOME/$(dirname "$f")"; cp -p "$bk/untracked/$f" "$HOME/$f"; }
                done
            fi

            rm -f "$STATE/migrations.done"
            say "rolled back. Restart the shell: qs kill; qs -n -d"
            ;;
    esac
}

cmd_version() {
    v=$(tr -d '[:space:]' < "$APSIS_DIR/VERSION" 2>/dev/null)
    printf 'Apsis %s' "${v:-unknown}"
    h=$(g rev-parse --short HEAD 2>/dev/null) && printf ' (%s)' "$h"
    printf '\n'
}

usage() {
    sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
    update)  shift; cmd_update "$@" ;;
    rollback) shift; cmd_restore "$@" ;;
    version) cmd_version ;;
    newer) shift; cmd_newer "$@" ;;
    migrate) run_migrations ;;
    -h|--help|help|"") usage ;;
    *) die "unknown command: $1 (update, rollback, version, newer)" ;;
esac
