#!/bin/sh
# Build stripped Lightpanda binaries from pinned sources inside the pinned build
# image. Intended to run on the self-hosted runner (needs docker + sudo docker).
#
#   ci-build.sh <outdir> <asset-version> <browser-commit> <v8-commit>
#
# Two invocations with different WORK dirs must produce identical stripped
# binaries; the workflow compares them and fails the run if they differ.
#
# Environment:
#   IMG        build image            (default: lp-ci-pinned)
#   WORK       scratch dir            (default: /srv/lp-ci/work/<version>-<pass>)
#   V8CACHE    V8 archive cache       (default: /srv/lp-ci/v8-cache)
#   V8_MODE    cache|build            (default: cache; "build" populates the cache)
#   DOCKER     docker command         (default: sudo -n docker)

set -eu

OUT=${1:?usage: ci-build.sh <outdir> <version> <browser-commit> <v8-commit>}
VERSION=${2:?version}
BROWSER_COMMIT=${3:?browser commit}
V8_COMMIT=${4:?v8 commit}

REPO=$(cd "$(dirname "$0")/.." && pwd)
IMG=${IMG:-lp-ci-pinned}
V8CACHE=${V8CACHE:-/srv/lp-ci/v8-cache}
V8_MODE=${V8_MODE:-cache}
DOCKER=${DOCKER:-sudo -n docker}
WORK=${WORK:-/srv/lp-ci/work/${VERSION}-$$}

log() { printf '[ci] %s\n' "$*"; }

mkdir -p "$OUT" "$WORK"
ZIG_VER=$($DOCKER run --rm --entrypoint /bin/sh "$IMG" -c 'zig version')
PATCH1=$(sha256sum "$REPO"/patches/0001-*.patch | cut -d' ' -f1)
KEY=$(printf '%s\n%s\n%s\n' "$V8_COMMIT" "$PATCH1" "$ZIG_VER" | sha256sum | cut -c1-16)
ARCH_DIR="$V8CACHE/$KEY"
log "version=$VERSION zig=$ZIG_VER v8cache-key=$KEY"

# ---------------------------------------------------------------- sources ----
SRC="$WORK/browser"
[ -d "$SRC/.git" ] || git clone -q --shallow-since=2026-10-10 \
    https://github.com/lightpanda-io/browser "$SRC"
git -C "$SRC" checkout -q "$BROWSER_COMMIT"
log "browser at $(git -C "$SRC" rev-parse --short HEAD)"

for p in "$REPO"/patches/000[2-9]-*.patch; do
    [ -e "$p" ] || continue
    if git -C "$SRC" apply --check "$p" 2>/dev/null; then
        git -C "$SRC" apply "$p"
        log "applied $(basename "$p")"
    else
        log "already applied or not applicable: $(basename "$p")"
    fi
done

# ------------------------------------------------------------- v8 archives ----
if [ ! -f "$ARCH_DIR/libc_v8_musl.a" ] || [ ! -f "$ARCH_DIR/libc_v8_musl_ia32.a" ]; then
    if [ "$V8_MODE" != "build" ]; then
        log "V8 archives missing in $ARCH_DIR and V8_MODE=$V8_MODE — re-run with v8_mode=build"
        exit 2
    fi
    log "building V8 for both arches (slow: ~30-60 min)"
    V8SRC="$WORK/v8"
    [ -d "$V8SRC/.git" ] || git clone -q https://github.com/lightpanda-io/zig-v8-fork "$V8SRC"
    git -C "$V8SRC" checkout -q "$V8_COMMIT"
    for p in "$REPO"/patches/0001-*.patch; do
        git -C "$V8SRC" apply --check "$p" 2>/dev/null && git -C "$V8SRC" apply "$p" || true
    done
    mkdir -p "$ARCH_DIR"
    # Build each target, then immediately fold the shim into that target's archive
    # and copy it into the cache. Doing the fold inside the same iteration avoids
    # having to guess which release_*/ dir belongs to which architecture.
    $DOCKER run --rm \
        -v "$V8SRC:/build/src/v8" \
        -v "$REPO:/repo:ro" \
        -v "$ARCH_DIR:/v8cache" \
        "$IMG" bash -lc '
            set -e
            cd /build/src/v8
            for tgt in x86_64 x86; do
                zig build -Dtarget=${tgt}-linux-musl -Doptimize=ReleaseFast prepare-v8
                zig build -Dtarget=${tgt}-linux-musl -Doptimize=ReleaseFast build-v8
                a=$(ls -t out/linux/release_*/obj/zig/libc_v8.a | head -1)
                [ -n "$a" ] || { echo "no libc_v8.a produced for ${tgt}"; exit 1; }
                work=$(mktemp -d)
                cp "$a" "$work/libc_v8_musl.a"
                zig cc -target ${tgt}-linux-musl -O2 -c /repo/build/musl_glibc_shim.c -o "$work/shim.o"
                zig ar r "$work/libc_v8_musl.a" "$work/shim.o"
                case "$tgt" in
                    x86) cp "$work/libc_v8_musl.a" /v8cache/libc_v8_musl_ia32.a ;;
                    *)   cp "$work/libc_v8_musl.a" /v8cache/libc_v8_musl.a ;;
                esac
                rm -rf "$work"
                echo "cached ${tgt} archive"
            done
        '
fi

log "v8 x86_64 $(sha256sum "$ARCH_DIR/libc_v8_musl.a" | cut -c1-16)…"
log "v8 i686   $(sha256sum "$ARCH_DIR/libc_v8_musl_ia32.a" | cut -c1-16)…"

# ------------------------------------------------------------------ build ----
# $1 arch suffix  $2 zig target  $3 extra zig args  $4 v8 archive basename
build_arch() {
    suffix=$1; target=$2; extra=$3; archive=$4
    out="lightpanda-$VERSION-$suffix-musl"
    log "building $out (target $target)"
    $DOCKER run --rm \
        -v "$SRC:/build/src/browser" \
        -v "$ARCH_DIR:/v8:ro" \
        "$IMG" bash -lc "
            set -e
            cd /build/src/browser
            command -v strip >/dev/null || { echo 'strip missing'; exit 1; }
            rustup target add i686-unknown-linux-musl >/dev/null 2>&1 || true
            zig build -Dtarget=$target-linux-musl -Doptimize=ReleaseFast $extra \
                -Dprebuilt_v8_path=/v8/$archive
            strip --strip-all -o /tmp/$out zig-out/bin/lightpanda
            cp /tmp/$out /build/src/browser/$out
            sha256sum /build/src/browser/$out
        "
    cp "$SRC/$out" "$OUT/$out"
}

build_arch x86_64 x86_64 ""                                  libc_v8_musl.a
build_arch i686   x86       "-Dcargo_target=i686-unknown-linux-musl" libc_v8_musl_ia32.a

# --------------------------------------------------------------- metadata ----
{
    echo "asset-version: $VERSION"
    echo "browser-commit: $(git -C "$SRC" rev-parse HEAD)"
    echo "v8-commit: $V8_COMMIT"
    echo "v8-archive-x86_64-sha256: $(sha256sum "$ARCH_DIR/libc_v8_musl.a" | cut -d' ' -f1)"
    echo "v8-archive-i686-sha256: $(sha256sum "$ARCH_DIR/libc_v8_musl_ia32.a" | cut -d' ' -f1)"
    echo "shim-sha256: $(sha256sum "$REPO/build/musl_glibc_shim.c" | cut -d' ' -f1)"
    echo "patch-0002-sha256: $(sha256sum "$REPO"/patches/0002-*.patch | cut -d' ' -f1)"
    echo "image-digest: $($DOCKER image inspect "$IMG" --format '{{.Id}}')"
    $DOCKER run --rm --entrypoint /bin/sh "$IMG" -c 'echo "zig: $(zig version)"; echo "rustc: $(rustc --version)"; echo "clang: $(clang --version | head -1)"' | sed 's/^/toolchain- /'
} > "$OUT/BUILDINFO.txt"

log "done: $(ls -l "$OUT" | tail -n +2 | awk '{printf "%s(%s) ", $9, $5}')"
