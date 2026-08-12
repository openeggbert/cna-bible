#!/usr/bin/env bash
# Shared artifact-operation lock for the CNA Bible tools. Call acquire_book_lock with either
# "exclusive" (anything that builds/mutates book artifacts) or "shared" (read-only inspection).

acquire_book_lock() {
    local requested_mode=$1
    local inherited_fd=${CNA_BIBLE_LOCK_FD:-}
    local existing_fd=${book_lock_fd:-}
    local existing_mode=${book_lock_mode:-}
    local lock_dir lock_dir_owner lock_dir_mode lock_digest lock_id lock_file prior_umask
    local inherited_identity lock_identity existing_identity opened_identity
    local lock_file_owner lock_file_mode lock_file_symlink

    case "$requested_mode" in
        exclusive|shared) ;;
        *)
            printf 'ERROR: invalid book-lock mode: %s\n' "$requested_mode" >&2
            return 1
            ;;
    esac

    if [ ! -d /proc/self/fd ]; then
        printf 'ERROR: artifact locking requires Linux procfs at /proc/self/fd\n' >&2
        return 1
    fi

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

    if ! lock_digest=$(printf '%s' "$repo_root" | sha256sum); then
        printf 'ERROR: could not derive the repository book-lock identity\n' >&2
        return 1
    fi
    lock_id=${lock_digest%% *}
    case "$lock_id" in
        *[!0-9a-f]*|'')
            printf 'ERROR: invalid repository book-lock identity\n' >&2
            return 1
            ;;
    esac
    if [ "${#lock_id}" -ne 64 ]; then
        printf 'ERROR: invalid repository book-lock identity length\n' >&2
        return 1
    fi
    lock_file="$lock_dir/${lock_id}.lock"
    if [ -e "$lock_file" ] || [ -L "$lock_file" ]; then
        read -r lock_file_owner lock_file_mode <<EOF
$(stat -Lc '%u %a' "$lock_file" 2>/dev/null || true)
EOF
        if [ -L "$lock_file" ] || [ ! -f "$lock_file" ] \
           || [ "$lock_file_owner" != "$EUID" ]; then
            if [ -L "$lock_file" ]; then lock_file_symlink=yes; else lock_file_symlink=no; fi
            printf 'ERROR: unsafe existing book-lock file (symlink=%s owner=%s mode=%s)\n' \
                "$lock_file_symlink" "${lock_file_owner:-missing}" \
                "${lock_file_mode:-missing}" >&2
            return 1
        fi
    fi
    lock_identity=$(stat -Lc '%d:%i' "$lock_file" 2>/dev/null || true)

    # Repeated compatible calls in one shell reuse the already-held descriptor. This matters for
    # future composed tools that source more than one artifact helper. Never silently upgrade a
    # shared lock to exclusive: another reader could hold it, and conversion would be racy.
    if [ -n "$existing_fd" ]; then
        existing_identity=$(stat -Lc '%d:%i' "/proc/self/fd/$existing_fd" 2>/dev/null || true)
        if [ -n "$existing_identity" ] && [ "$existing_identity" = "$lock_identity" ] \
           && { [ "$existing_mode" = "exclusive" ] || [ "$requested_mode" = "shared" ]; }; then
            return 0
        fi
        printf 'ERROR: incompatible or invalid repeated book-lock acquisition\n' >&2
        return 1
    fi

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
        if [ -z "$inherited_identity" ] || [ "$inherited_identity" != "$lock_identity" ] \
           || ! flock -n "$inherited_fd" 2>/dev/null; then
            printf 'ERROR: inherited book-lock descriptor does not match this repository\n' >&2
            return 1
        fi
        book_lock_fd=$inherited_fd
        book_lock_mode=exclusive
        return 0
    fi

    prior_umask=$(umask)
    umask 077
    # Append-open avoids truncating any path if a same-user process races the pre-open check.
    # Once the descriptor is bound to the current regular inode, migrate legacy permissive modes
    # through procfs without reopening by name.
    exec {book_lock_fd}>>"$lock_file"
    umask "$prior_umask"
    opened_identity=$(stat -Lc '%d:%i' "/proc/self/fd/$book_lock_fd" 2>/dev/null || true)
    lock_identity=$(stat -Lc '%d:%i' "$lock_file" 2>/dev/null || true)
    lock_file_owner=$(stat -Lc '%u' "/proc/self/fd/$book_lock_fd" 2>/dev/null || true)
    if [ -L "$lock_file" ] || [ -z "$opened_identity" ] \
       || [ "$opened_identity" != "$lock_identity" ] || [ "$lock_file_owner" != "$EUID" ]; then
        printf 'ERROR: unsafe book-lock file (owner=%s mode=%s)\n' \
            "${lock_file_owner:-missing}" "untrusted" >&2
        exec {book_lock_fd}>&-
        unset book_lock_fd book_lock_mode
        return 1
    fi
    if ! chmod 600 "/proc/self/fd/$book_lock_fd" 2>/dev/null; then
        printf 'ERROR: could not restrict book-lock file to mode 600\n' >&2
        exec {book_lock_fd}>&-
        unset book_lock_fd book_lock_mode
        return 1
    fi
    lock_file_mode=$(stat -Lc '%a' "/proc/self/fd/$book_lock_fd" 2>/dev/null || true)
    if [ "$lock_file_mode" != "600" ]; then
        printf 'ERROR: unsafe book-lock file mode after restriction (%s)\n' \
            "${lock_file_mode:-missing}" >&2
        exec {book_lock_fd}>&-
        unset book_lock_fd book_lock_mode
        return 1
    fi
    if [ "$requested_mode" = "exclusive" ]; then
        if ! flock -n -x "$book_lock_fd"; then
            printf 'ERROR: another CNA Bible artifact operation is already running\n' >&2
            exec {book_lock_fd}>&-
            unset book_lock_fd book_lock_mode
            return 1
        fi
    elif ! flock -n -s "$book_lock_fd"; then
        printf 'ERROR: a CNA Bible build is already running\n' >&2
        exec {book_lock_fd}>&-
        unset book_lock_fd book_lock_mode
        return 1
    fi
    book_lock_mode=$requested_mode
}
