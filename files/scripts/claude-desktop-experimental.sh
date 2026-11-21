#!/usr/bin/env bash
#
# install-official.sh — install Anthropic's official Claude Desktop Linux build
#                       on Fedora directly, without building an RPM.
#
# Derived from build-official.sh in dewzor/claude-desktop-fedora (MIT/Apache-2.0).
# The fetch, signature and checksum checks are unchanged. Instead of wrapping
# the payload in an RPM, this script unpacks it and installs it into a prefix.
#
# Non-interactive; meant for automated builds. Configured only via environment:
#
#   PREFIX   install prefix (default: /usr/local), e.g. PREFIX=/usr inside a
#            Containerfile build to bake it into a bootc image. Must be
#            writable by the invoking user; sudo is never used.
#   DEB      path to an already-downloaded .deb to install instead of
#            fetching the newest one from Anthropic's signed apt repository.
#            A local .deb is not checked against the signed index.
#
# A manifest of installed files is kept so upgrades remove exactly what the
# previous version installed.
#
set -euo pipefail
# Pin the locale so every check gives the same result on every system
# (see build-official.sh for the Turkish-i and legacy-CJK breakage this avoids).
export LC_ALL=C.UTF-8

ARCH_DEB="amd64"
ARCH_RPM="x86_64"
APT_BASE="https://downloads.claude.ai/claude-desktop/apt/stable"
KEY_FPR="31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"
anthropic_key() {
    cat <<'KEY'
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBGnK73ABEACnbytJXkjweYrwIr0aLEFRlH+C0nF44KxFc7gQmJ6PjSPMGZAD
dxZcaixU7zZl8WxEpVO0wLmIH8cf2zGOdyuZg1Yaugk1vHb2b8WBhAGCQJdPgB8W
XquedepEYtk56uP/gCoTjJDUZluEGBHnlnuujSJ4orxEdhSykEoAUfJZGEILPpMd
bphFt/Sn+Eb/TxM5jpKPdwnv8AShNF/1mZU1fWTQq9tRKJUakZj04gdaDFElQXak
CtTij+GT6yoYCARSHwGO+PC/Pr6q4tc+D7LRjxSBvUWDoFSmlqb/PJ1hj9D/7I2O
e4XXniAPWMR56KvxHlzOzrNQdJujbJdSkCwh1ZijkSd3y8ayW5WYUTGdRab99NUw
agzlabe/VVF6kzJ0Scn5q3PihB2Y9Bwo0CKnkYk7a7KT77EWv0Kkq+VHmOtqX3a2
hhX+b6a6ve9rzJ1qZYGj+obv/C3Sx1LzUjAfqVy7RJDf2uAoP5t2g8u/TkSpUxhM
VEjZBkSxYZhMyzQM6t8IgkUfnSrIPTHixbDWARZ4beMOBjxyPZK1nP7OOrNR3TkK
JtwLMQAabURCDnL0PjS0iwBTU4jtumBD1XSULyWuoTvMljrpQr1nV1oDyOt0OLqa
KA2McWtd9PdXhC8y2EIg7TmrTlJLfHYbdmkiCYj4J49Q8HWkN/6WE+RTUwARAQAB
tD5BbnRocm9waWMgQ2xhdWRlIENvZGUgUmVsZWFzZSBTaWduaW5nIDxzZWN1cml0
eUBhbnRocm9waWMuY29tPokCUQQTAQoAOxYhBDHd3iTd+rZ59C170rqpKf8afsrO
BQJpyu9wAhsPBQsJCAcCAiICBhUKCQgLAgQWAgMBAh4HAheAAAoJELqpKf8afsrO
l5IP/2I8X1dFy5xYczWB/coIxGjuzS/V6ByZGZZEJsbr04pmuHiFUykJqPGWGQ6q
U0YF5iEwvEkaagS5m7DzhSEf3FM3Cgafax/6d70tar9Vr1D+w6uPfxetu7u/WYJp
aolIsdh5fTrBh9zSM1Njl8FM8wG8CwZQjS33Oa7d8cwRkgdUWbt6LXgz+cTQNuBn
BgW6Ks7oZFI25dfu0ojDR+aDFJg4+4wZoyDLPvJz1SIrJ5WFGs67zsx9SfS3yZnf
XKmBe+f0dUy+GJ2nFZrXFf99+c0dPEHYO8DCeAHZizjkFrdYtUHdDU0YDYEGkLJa
bE+pgcpkHf5EvsZzHsyDbl95W/eh7pcXMbwkN+W4CBYUE9X4uHhqzWaC5yAVRWUA
1BJ9V4LjZfHPLEJt0I3TxzXiEg9/BVeaTYq9RjaxIFo9Nfk158HqJY6SA5jslBlx
Gv/No8u+xVcze2UJyGVfEIUfm92+0UAIkny3+5cuVV0ICzJxXlXj0CnLM9Lt50wE
p3suVwuBEviCbZ08eAH1Ht8gbBdSsiOkIU8CX3v/scwHHx5q0+NBL6xLrQObg13a
tRXBlKObfElkPN3lTUbUnJOW4U8uSjH8VRP+AujKWMDFe7x0zCs+iYY1mTOvbrTS
9n3CmZUmbynZ+E/QWNENpW/pDNZdWFy43PASmML5FHu4m9Sn
=oqMI
-----END PGP PUBLIC KEY BLOCK-----
KEY
}

WORK=""
DEB="${DEB:-}"
PREFIX="${PREFIX:-/usr}"

die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }

[ "$(uname -m)" = "$ARCH_RPM" ] || die "this script installs the $ARCH_RPM build only; this host is $(uname -m)"

case "$PREFIX" in /*) ;; *) die "PREFIX must be an absolute path: $PREFIX" ;; esac
PREFIX="${PREFIX%/}"
[ -n "$PREFIX" ] || die "PREFIX=/ is not supported; use /usr"
APP_DIR="$PREFIX/lib/claude-desktop"
MANIFEST="$APP_DIR/.install-manifest"
VERSION_FILE="$APP_DIR/.version"

# On a booted Fedora Atomic / bootc system, /usr is the read-only image.
# /usr/local and /opt are writable (they point into /var). Inside a
# Containerfile build /run/ostree-booted does not exist, so PREFIX=/usr works there.
if [ -e /run/ostree-booted ]; then
    case "$PREFIX/" in
        /usr/local/*) ;;
        /usr/*) die "$PREFIX is read-only on this image-based system; use the default /usr/local, or install it in your image's Containerfile" ;;
    esac
fi

# The prefix (or the nearest directory that exists above it) must be writable
# by us; there is no sudo fallback.
AS_ROOT=0
if [ "$(id -u)" -eq 0 ]; then
    AS_ROOT=1
else
    probe="$PREFIX"
    while [ ! -e "$probe" ]; do probe="$(dirname "$probe")"; done
    if [ ! -w "$probe" ] || { [ -e "$APP_DIR" ] && [ ! -w "$APP_DIR" ]; }; then
        die "$PREFIX is not writable; run as root or set PREFIX to a writable path"
    fi
fi

app_running() { pgrep -f "^$APP_DIR/claude-desktop" >/dev/null 2>&1; }
installed_version() { cat "$VERSION_FILE" 2>/dev/null || echo none; }

refresh_caches() {
    local share="$PREFIX/share"
    if [ -d "$share/applications" ] && command -v update-desktop-database >/dev/null; then
        update-desktop-database "$share/applications" >/dev/null 2>&1 || true
    fi
    if [ -d "$share/mime/packages" ] && command -v update-mime-database >/dev/null; then
        update-mime-database "$share/mime" >/dev/null 2>&1 || true
    fi
    if [ -d "$share/icons/hicolor" ] && command -v gtk-update-icon-cache >/dev/null; then
        touch --no-create "$share/icons/hicolor" 2>/dev/null || true
        gtk-update-icon-cache -f -t "$share/icons/hicolor" >/dev/null 2>&1 || true
    fi
}

# Remove the files a previous install put outside the app directory.
# Manifest entries are paths relative to PREFIX; anything odd is skipped.
remove_manifest_files() {
    local manifest="$1" rel
    [ -f "$manifest" ] || return 0
    while IFS= read -r rel; do
        case "$rel" in ''|/*|*..*|lib/claude-desktop|lib/claude-desktop/*) continue ;; esac
        printf '%s\0' "$PREFIX/$rel"
    done < "$manifest" | xargs -0 -r rm -f --
}

# ----------------------------------------------------------------- checks ----
for c in curl gpg sha256sum; do
    command -v "$c" >/dev/null || die "missing required command: $c"
done
for c in ar tar xz file find xargs; do
    command -v "$c" >/dev/null || die "missing required command: $c (try: dnf install binutils tar xz file findutils)"
done

cleanup() {
    if [ -n "$WORK" ] && [ -d "$WORK" ]; then
        rm -rf "$WORK"
    fi
}
trap cleanup EXIT

WORK="$(mktemp -d -t claude-desktop-install.XXXXXXXX)"

sha256_of() { sha256sum -- "$1" | cut -d' ' -f1; }

# Walk the apt chain of trust: pinned key -> InRelease signature (and its
# Valid-Until, so an old index cannot be replayed) -> Packages checksum ->
# newest claude-desktop entry. Sets LATEST_VERSION, LATEST_SHA256,
# LATEST_FILENAME and LATEST_SIZE. Prints nothing on success.
resolve_latest() {
    local gnupg="$WORK/gnupg" status valid_until index want entry
    mkdir -p -m 700 "$gnupg"
    anthropic_key | gpg --homedir "$gnupg" --batch --quiet --import 2>/dev/null \
        || die "could not import Anthropic's release key"

    curl -fsS --max-time 60 -o "$WORK/InRelease" "$APT_BASE/dists/stable/InRelease" \
        || die "could not fetch $APT_BASE/dists/stable/InRelease"
    # --decrypt on a clearsigned file writes out only the signed text, so
    # nothing below reads bytes the signature does not cover.
    status="$(gpg --homedir "$gnupg" --batch --status-fd 1 \
                  --output "$WORK/Release" --decrypt "$WORK/InRelease" 2>/dev/null)" \
        || die "InRelease signature check failed"
    # gpg exits 0 for a valid signature even when the key has expired or been
    # revoked, so read the status lines: one signature must be GOODSIG with a
    # VALIDSIG whose signing primary key is the pinned fingerprint.
    local verdict=0
    printf '%s\n' "$status" | awk -v f="$KEY_FPR" '
        $2 == "NEWSIG" { g++ }
        $2 ~ /^(BADSIG|ERRSIG|EXPSIG|EXPKEYSIG|REVKEYSIG)$/ { bad = 1 }
        $2 == "GOODSIG" { good[g] = 1 }
        $2 == "VALIDSIG" && $NF == f { pinned[g] = 1 }
        END {
            if (bad) exit 2
            for (i in good) if (pinned[i]) exit 0
            exit 1
        }' || verdict=$?
    case "$verdict" in
        0) ;;
        2) die "InRelease carries a bad, expired or revoked signature; refusing it" ;;
        *) die "InRelease is not signed by Anthropic's release key $KEY_FPR" ;;
    esac

    valid_until="$(sed -n 's/^Valid-Until: //p' "$WORK/Release")"
    [ -n "$valid_until" ] || die "the signed index carries no Valid-Until date"
    [ "$(date -d "$valid_until" +%s)" -gt "$(date +%s)" ] \
        || die "the signed index expired on $valid_until; refusing a stale index"

    index="main/binary-$ARCH_DEB/Packages"
    want="$(awk -v p="$index" '/^SHA256:/ { s = 1; next } /^[^ ]/ { s = 0 } s && $3 == p { print $1 }' "$WORK/Release")"
    [ -n "$want" ] || die "the signed index does not list $index"
    curl -fsS --max-time 120 -o "$WORK/Packages" "$APT_BASE/dists/stable/$index" \
        || die "could not fetch $APT_BASE/dists/stable/$index"
    [ "$(sha256_of "$WORK/Packages")" = "$want" ] \
        || die "$index does not match the checksum in the signed index"

    # Check every claude-desktop stanza's fields; any malformed candidate
    # stops the run instead of being skipped. Then keep the newest.
    local parsed
    parsed="$(awk -v RS= -v arch="$ARCH_DEB" '
        {
            delete c; delete val
            n = split($0, l, "\n")
            for (i = 1; i <= n; i++) {
                if (l[i] !~ /^[A-Za-z0-9-]+: /) continue
                k = l[i]; sub(/: .*/, "", k)
                c[k]++; val[k] = substr(l[i], length(k) + 3)
            }
            if (val["Package"] != "claude-desktop") next
            why = ""
            if (c["Package"] != 1 || c["Version"] != 1 || c["Filename"] != 1 || c["SHA256"] != 1 || c["Architecture"] != 1 || c["Size"] > 1)
                why = "missing or repeated field"
            else if (val["Architecture"] != arch) why = "Architecture " val["Architecture"]
            else if (val["Version"] !~ /^[0-9][0-9A-Za-z.+~]*$/) why = "Version " val["Version"]
            else if (length(val["SHA256"]) != 64 || val["SHA256"] ~ /[^0-9a-f]/) why = "SHA256 " val["SHA256"]
            else if (val["Filename"] !~ /^pool\/[A-Za-z0-9._+~\/-]+\.deb$/ || index(val["Filename"], "..")) why = "Filename " val["Filename"]
            else if (c["Size"] && val["Size"] !~ /^[0-9]+$/) why = "Size " val["Size"]
            if (why != "") { print "BAD\t" val["Version"] ": " why; bad = 1; next }
            print val["Version"] "\t" val["SHA256"] "\t" val["Filename"] "\t" val["Size"]
        }
        END { exit bad }' "$WORK/Packages")" \
        || die "malformed claude-desktop entry in the signed index: $(printf '%s\n' "$parsed" | awk -F'\t' '$1 == "BAD" { print $2; exit }')"
    entry="$(printf '%s\n' "$parsed" | sort -t $'\t' -V -k1,1 | tail -1)"
    [ -n "$entry" ] || die "no claude-desktop entry in the signed Packages index"
    IFS=$'\t' read -r LATEST_VERSION LATEST_SHA256 LATEST_FILENAME LATEST_SIZE <<<"$entry"
    [[ "$LATEST_VERSION" =~ ^[0-9][0-9A-Za-z.+~]*$ ]] \
        || die "unsupported Version in the signed index: $LATEST_VERSION"
    [[ "$LATEST_SHA256" =~ ^[0-9a-f]{64}$ ]] \
        || die "malformed SHA256 in the signed index: $LATEST_SHA256"
    [[ "$LATEST_FILENAME" =~ ^pool/[A-Za-z0-9._+~/-]+\.deb$ && "$LATEST_FILENAME" != *..* ]] \
        || die "unexpected Filename in the signed index: $LATEST_FILENAME"
    [[ "${LATEST_SIZE:-}" =~ ^[0-9]{1,12}$ ]] || LATEST_SIZE=0
}

# Stop early if this version is already installed.
check_version() {
    local want="$1"
    if [ "$(installed_version)" = "$want" ]; then
        info "Claude Desktop $want is already installed in $PREFIX"
        exit 0
    fi
}

# ---------------------------------------------------------------- fetch ------
EXPECT_VERSION=""
if [ -n "$DEB" ]; then
    [ -f "$DEB" ] || die "DEB: no such file: $DEB"
    warn "using local package $DEB without checking it against the signed index"
    cp -- "$DEB" "$WORK/claude.deb"
else
    info "checking Anthropic's signed apt repository..."
    resolve_latest
    info "found: claude-desktop $LATEST_VERSION (signature and index checksum verified; installed: $(installed_version))"
    check_version "$LATEST_VERSION"
    info "downloading (~$(( 10#${LATEST_SIZE:-0} / 1048576 )) MB)..."
    curl -fsSL --globoff --max-time 900 -o "$WORK/claude.deb" "$APT_BASE/$LATEST_FILENAME" \
        || die "download failed"
    [ "$(sha256_of "$WORK/claude.deb")" = "$LATEST_SHA256" ] \
        || die "the downloaded .deb does not match the SHA256 in the signed index"
    info "download matches the signed SHA256"
    EXPECT_VERSION="$LATEST_VERSION"
fi

file -b "$WORK/claude.deb" | grep -q '^Debian binary package' \
    || die "downloaded file is not a Debian package"

# -------------------------------------------------------------- unpack -------
info "unpacking..."
mkdir -p "$WORK/ctrl" "$WORK/payload"
( cd "$WORK" && ar x claude.deb ) || die "ar could not read the .deb"

CTRL_TAR="$(find "$WORK" -maxdepth 1 -name 'control.tar.*' -print -quit)"
DATA_TAR="$(find "$WORK" -maxdepth 1 -name 'data.tar.*'    -print -quit)"
[ -n "$CTRL_TAR" ] || die "no control.tar.* inside the .deb"
[ -n "$DATA_TAR" ] || die "no data.tar.* inside the .deb"

tar -xf "$CTRL_TAR" -C "$WORK/ctrl"
VERSION="$(sed -n 's/^Version:[[:space:]]*//p' "$WORK/ctrl/control" | head -1)"
[ -n "$VERSION" ] || die "could not read Version: from the package control file"
[ -z "$EXPECT_VERSION" ] || [ "$VERSION" = "$EXPECT_VERSION" ] \
    || die "package says version $VERSION but the signed index says $EXPECT_VERSION"
info "version: $VERSION"
[ -n "$EXPECT_VERSION" ] || check_version "$VERSION"

tar -xf "$DATA_TAR" -C "$WORK/payload"
SRC="$WORK/payload/usr/lib/claude-desktop"
[ -d "$SRC" ] || die "unexpected payload layout: usr/lib/claude-desktop not found"
[ -x "$SRC/claude-desktop" ] || die "unexpected payload layout: usr/lib/claude-desktop/claude-desktop missing"

# Sanity-check the two modules that make Claude Code work.
NATIVE="$SRC/resources/app.asar.unpacked/node_modules/@ant/claude-native/claude-native-binding.node"
PTY="$SRC/resources/app.asar.unpacked/node_modules/node-pty/prebuilds/linux-x64/pty.node"
for m in "$NATIVE" "$PTY"; do
    if [ -f "$m" ]; then
        file -b "$m" | grep -q '^ELF 64-bit.*x86-64' \
            || die "$(basename "$m") is not a Linux x86-64 binary — wrong package?"
    else
        warn "expected native module missing: ${m#"$WORK/payload/"}"
    fi
done
info "native modules checked (claude-native, node-pty)"

# --------------------------------------------------------------- stage -------
# Build the tree that goes into PREFIX (bin/ and share/), rewriting upstream's
# hard-coded /usr paths to this prefix. The app directory is copied separately.
info "staging files for $PREFIX..."
STAGE="$WORK/stage"
mkdir -p "$STAGE/bin" "$STAGE/share"
if [ -d "$WORK/payload/usr/share" ]; then
    cp -a "$WORK/payload/usr/share/." "$STAGE/share/"
fi
rm -rf "$STAGE/share/lintian"   # Debian packaging metadata

ls "$STAGE"/share/applications/*.desktop >/dev/null 2>&1 || die "no .desktop file in the payload"

# Upstream's postinst copies these out of resources/ at install time; do the same.
RES="$SRC/resources"
stage_extra() {  # stage_extra SRC-under-resources DEST-under-stage
    [ -f "$RES/$1" ] || { warn "not in this build, skipping: resources/$1"; return 0; }
    install -Dm644 "$RES/$1" "$STAGE/$2"
}
stage_extra linux-mime/com.anthropic.Claude.xml \
            share/mime/packages/com.anthropic.Claude.xml
stage_extra gnome-search-provider/com.anthropic.Claude.search-provider.ini \
            share/gnome-shell/search-providers/com.anthropic.Claude.search-provider.ini
stage_extra gnome-search-provider/com.anthropic.Claude.SearchProvider.service \
            share/dbus-1/services/com.anthropic.Claude.SearchProvider.service

# Launcher. bin/ and lib/ are siblings in every prefix, so a relative link works.
UP_BIN="$WORK/payload/usr/bin/claude-desktop"
if [ -f "$UP_BIN" ] && [ ! -L "$UP_BIN" ]; then
    # A wrapper script rather than a link: point it at this prefix.
    sed "s|/usr/lib/claude-desktop|$APP_DIR|g" "$UP_BIN" > "$STAGE/bin/claude-desktop"
    chmod 755 "$STAGE/bin/claude-desktop"
else
    ln -s ../lib/claude-desktop/claude-desktop "$STAGE/bin/claude-desktop"
fi
# The `ccd` launcher only ships in some builds; link it the way postinst does.
if [ -x "$RES/bin/ccd" ]; then
    ln -s ../lib/claude-desktop/resources/bin/ccd "$STAGE/bin/ccd"
fi

# Menu entries and the D-Bus service name absolute /usr paths (or rely on
# claude-desktop being on PATH, which ~/.local/bin may not be in a desktop session).
for f in "$STAGE"/share/applications/*.desktop; do
    sed -i -E \
        -e "s#^(Try)?Exec=(/usr/bin/)?claude-desktop#\\1Exec=$PREFIX/bin/claude-desktop#" \
        -e "s#/usr/lib/claude-desktop#$APP_DIR#g" "$f"
done
for f in "$STAGE"/share/dbus-1/services/*.service; do
    [ -e "$f" ] || continue
    sed -i -e "s#/usr/lib/claude-desktop#$APP_DIR#g" \
           -e "s#/usr/bin/claude-desktop#$PREFIX/bin/claude-desktop#g" "$f"
done

# Record what goes outside the app directory, for upgrades.
( cd "$STAGE" && find . ! -type d | sed 's|^\./||' | sort ) > "$SRC/.install-manifest"
printf '%s\n' "$VERSION" > "$SRC/.version"

# -------------------------------------------------------------- install ------
app_running && die "Claude Desktop is running; quit it first (tray icon > Quit), then re-run"

if [ "$PREFIX" = /usr ] && command -v rpm >/dev/null && rpm -q claude-desktop >/dev/null 2>&1; then
    die "the claude-desktop RPM owns /usr/lib/claude-desktop; remove it first: dnf remove claude-desktop"
fi
if command -v rpm >/dev/null && rpm -q claude-desktop >/dev/null 2>&1; then
    warn "the claude-desktop RPM is also installed; there will be two Claude entries until it is removed"
fi

TAR_OWNER=()
[ "$AS_ROOT" -eq 1 ] && TAR_OWNER=(--owner=0 --group=0 --numeric-owner)

info "installing Claude Desktop $VERSION into $PREFIX..."
mkdir -p "$PREFIX/lib" "$PREFIX/bin" "$PREFIX/share"

# Copy the new app next to the old one, then swap, so a failed copy never
# leaves a half-installed app behind.
rm -rf -- "$APP_DIR.new" "$APP_DIR.old"
mkdir -m 755 "$APP_DIR.new"
tar -C "$SRC" "${TAR_OWNER[@]}" -cf - . | tar -C "$APP_DIR.new" -xpf - \
    || die "copying the app into $APP_DIR.new failed"

# Chromium's SUID sandbox helper: upstream ships it 4755 root, and unpacking
# as a normal user drops that. Restore it when installing as root.
if [ -f "$APP_DIR.new/chrome-sandbox" ]; then
    if [ "$AS_ROOT" -eq 1 ]; then
        chown root:root "$APP_DIR.new/chrome-sandbox"
        chmod 4755 "$APP_DIR.new/chrome-sandbox"
        info "chrome-sandbox setuid bit restored"
    else
        info "user install: chrome-sandbox is not setuid; Chromium uses the user-namespace sandbox (enabled on Fedora)"
    fi
fi

# Drop files the previous version installed outside the app dir, then swap.
if [ -f "$MANIFEST" ]; then
    remove_manifest_files "$MANIFEST"
fi
[ -d "$APP_DIR" ] && mv -- "$APP_DIR" "$APP_DIR.old"
mv -- "$APP_DIR.new" "$APP_DIR"
rm -rf -- "$APP_DIR.old"

# --no-overwrite-dir keeps the owner and mode of existing directories such as
# /usr/local/share.
tar -C "$STAGE" "${TAR_OWNER[@]}" -cf - bin share \
    | tar -C "$PREFIX" --no-overwrite-dir -xpf - \
    || die "copying launcher, menu entry and icons into $PREFIX failed"

refresh_caches

info "installed Claude Desktop $VERSION in $APP_DIR"
