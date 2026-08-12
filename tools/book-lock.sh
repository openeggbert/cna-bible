#!/usr/bin/env bash
# Shared artifact-operation lock for the CNA Bible tools. Call acquire_book_lock with either
# "exclusive" (anything that builds/mutates book artifacts) or "shared" (read-only inspection).

acquire_book_lock() {
    local requested_mode=$1
    local inherited_fd=${CNA_BIBLE_LOCK_FD:-}
    local lock_dir lock_dir_owner lock_dir_mode lock_id lock_file prior_umask
    local inherited_identity lock_identity

    case "$requested_mode" in
        exclusive|shared) ;;
        *)
            printf 'ERROR: invalid book-lock mode: %s\n' "$requested_mode" >&2
            return 1
            ;;
    esac

    lock_dir="/tmp/cna-bible-locks-$EUID"
    if ! mkdir -m 700 "$lock_dir" 2>/dev/null && [ ! -d "$lock_dir" ]; then
        printf 'ERROR: could not create private book-lock directory\n' >&2
        return 1
    fi
    read -r lock_dir_owner lock_dir_mode <<EOF
$(stat -c '%u %a' "$lock_dir" 2>/dev/null || true)
EOF
    if [ -L "$lock_dir" ] || [ ! -d "$lock_dir" ] \
       || [ "$lock_dir_owner" != "$EUID" ] || [ "$lock_dir_mode" != "700" ]; then
        printf 'ERROR: unsafe book-lock directory (owner=%s mode=%s)\n' \
            "${lock_dir_owner:-missing}" "${lock_dir_mode:-missing}" >&2
        return 1
    fi

    lock_id=$(printf '%s' "$repo_root" | sha256sum | awk '{print $1}')
    lock_file="$lock_dir/${lock_id}.lock"

    # A sealed build keeps its exclusive descriptor open while invoking verify-book --no-build.
    # Reuse that exact open file description rather than trying to convert a child lock, but prove
    # that an environment-supplied descriptor names this repository's actual lock inode.
    if [ -n "$inherited_fd" ]; then
        case "$inherited_fd" in
            *[!0-9]*|'')
                printf 'ERROR: invalid inherited book-lock descriptor\n' >&2
                return 1
                ;;
        esac
        inherited_identity=$(stat -Lc '%d:%i' "/proc/self/fd/$inherited_fd" 2>/dev/null || true)
        lock_identity=$(stat -Lc '%d:%i' "$lock_file" 2>/dev/null || true)
        if [ -z "$inherited_identity" ] || [ "$inherited_identity" != "$lock_identity" ] \
           || ! flock -n "$inherited_fd" 2>/dev/null; then
            printf 'ERROR: inherited book-lock descriptor does not match this repository\n' >&2
            return 1
        fi
        book_lock_fd=$inherited_fd
        return 0
    fi

    prior_umask=$(umask)
    umask 077
    exec {book_lock_fd}>"$lock_file"
    umask "$prior_umask"
    if [ "$requested_mode" = "exclusive" ]; then
        if ! flock -n -x "$book_lock_fd"; then
            printf 'ERROR: another CNA Bible artifact operation is already running\n' >&2
            return 1
        fi
    elif ! flock -n -s "$book_lock_fd"; then
        printf 'ERROR: a CNA Bible build is already running\n' >&2
        return 1
    fi
}
