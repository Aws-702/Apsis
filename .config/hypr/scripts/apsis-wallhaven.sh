#!/bin/sh
# Browse and fetch wallpapers from wallhaven.cc (public API, safe for work only).
#   apsis-wallhaven.sh search [QUERY] [PAGE] [SORT]   SORT: toplist relevance random date_added views favorites
#   apsis-wallhaven.sh get ID [apply]                 download into ~/Apsis/wallpapers, apply it too
#   apsis-wallhaven.sh thumb ID URL                   cache a thumbnail and print its path
# Edit: APSIS_WALLS for the folder; the API query in search.

api="${APSIS_WALLHAVEN_API:-https://wallhaven.cc/api/v1}"
dir="${APSIS_WALLS:-$HOME/Apsis/wallpapers}"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/apsis/wallhaven"
TAB=$(printf '\t')

for need in curl jq; do
    command -v "$need" >/dev/null 2>&1 || { echo "wallhaven: needs $need" >&2; exit 1; }
done

urlenc() { printf '%s' "$1" | jq -sRr @uri; }
valid_id() { printf '%s' "$1" | grep -Eq '^[a-z0-9]{4,12}$'; }

case "$1" in
search)
    q="$2"; page="${3:-1}"; sort="${4:-toplist}"
    printf '%s' "$page" | grep -Eq '^[0-9]{1,4}$' || page=1
    case "$sort" in toplist|relevance|random|date_added|views|favorites) ;; *) sort=toplist ;; esac

    url="$api/search?q=$(urlenc "$q")&categories=111&purity=100&sorting=$sort&page=$page"
    json=$(curl -fsS --max-time 20 "$url") || { echo "wallhaven: search failed (offline, or rate limited)" >&2; exit 1; }
    printf '%s' "$json" | jq -r '
        (.meta.last_page // 1) as $last |
        .data[]? | [ .id, .thumbs.small, .path, .resolution, $last ] | map(tostring) | @tsv' 2>/dev/null \
        | while IFS="$TAB" read -r id th full res last; do
            valid_id "$id" || continue
            case "$th$full" in *[!A-Za-z0-9:/._-]*) continue ;; esac
            printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$th" "$full" "$res" "$last"
        done
    ;;
get)
    id="$2"
    valid_id "$id" || { echo "wallhaven: bad id" >&2; exit 2; }
    mkdir -p "$dir"
    full=$(curl -fsS --max-time 20 "$api/w/$id" | jq -r '.data.path // empty') \
        || { echo "wallhaven: lookup failed" >&2; exit 1; }
    case "$full" in https://*) ;; *) echo "wallhaven: no download link" >&2; exit 1 ;; esac
    ext=${full##*.}
    printf '%s' "$ext" | grep -Eq '^(jpg|jpeg|png|webp)$' || { echo "wallhaven: odd file type" >&2; exit 1; }
    out="$dir/wallhaven-$id.$ext"
    if [ ! -s "$out" ]; then
        if curl -fsS --max-time 120 -o "$out.part" "$full"; then
            mv "$out.part" "$out"
        else
            rm -f "$out.part"; echo "wallhaven: download failed" >&2; exit 1
        fi
    fi
    [ "$3" = apply ] && "$(dirname "$0")/apsis-wall.sh" "$out"
    printf '%s\n' "$out"
    ;;
thumb)
    id="$2"; url="$3"
    valid_id "$id" || exit 2
    case "$url" in https://*) ;; *) exit 2 ;; esac
    mkdir -p "$cache"
    out="$cache/$id.jpg"
    if [ ! -s "$out" ]; then
        if curl -fsS --max-time 20 -o "$out.part" "$url"; then mv "$out.part" "$out"; else rm -f "$out.part"; fi
    fi
    [ -s "$out" ] || exit 1
    printf '%s\n' "$out"
    ;;
*)
    sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac
