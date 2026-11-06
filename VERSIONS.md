# Build provenance (pinned inputs)

What the released binaries were actually built from. The recipe is in
[build/README.md](build/README.md).

## Upstream

| Field | Value |
|---|---|
| Project | [lightpanda-io/browser](https://github.com/lightpanda-io/browser) |
| Build commit | **`f734e7f6aebc945fb8340284bfddd43244bf49ff`** |
| Position | upstream `main`, 2026-10-18 — **91 commits after tag `1.0.1`** |
| Release line | `1.0.1` (tag `1.0.1` = `99edca45844b5968c3ec8e50ad8e1acec8f3b759`, 2026-10-15) |
| Version string inside the binary | `1.1.0-dev` |

The build tree was a shallow clone of `main` (no tags present), so the binaries are a
**post-1.0.1 main snapshot**, not the `1.0.1` tag itself. The release is named `1.0.1-main.20261018-r1`
because it is based on the `1.0.1` release line; the exact commit is the one above.
```sh
git clone https://github.com/lightpanda-io/browser
git checkout f734e7f6aebc945fb8340284bfddd43244bf49ff   # what the binaries were built from
```

Delta vs the `1.0.1` tag: 91 commits, mostly `webapi`/`session`/`cache`/`tree` work
(see the [compare view](https://github.com/lightpanda-io/browser/compare/99edca45844b5968c3ec8e50ad8e1acec8f3b759...f734e7f6aebc945fb8340284bfddd43244bf49ff)).

`lightpanda version` prints `1.1.0-dev` because upstream's `build.zig.zon` declares the
*next development* version. Tags `1.0.1`, `1.0.2` and `1.0.3` all ship that same string,
which is why releases here are named after the release line, not the string.

## Dependencies (as pinned in `build.zig.zon` @ tag `1.0.1`)

| Dependency | Pin |
|---|---|
| `v8` (zig-v8-fork) | `b73e4fa2d0afe5036745ae7d332cc5cb7e7adb53` |
| `brotli` | `028fb5a23661f123017c060daa546b55cf4bde29` (v1.2.0) |
| `zlib` | `v1.3.2` |
| `zstd` | `v1.5.7` |
| `nghttp2` | `v1.70.0` |
| `boringssl-zig` | `5b5ad66f65c5cc4323680ab71284403598251678` |
| `curl` | `curl-8_23_0` |
| `sqlite3` | amalgamation `3530200` |
| `zenai` | `8bfbb3e5788d278a63708db8ee5f58aa589f9fff` |
| `isocline` | `4a99434bee4a5ed04c1639514224d48cd55e1405` |
| `pcre2` | `9ad4a2e956876747a5022bf04614c7e39e71d4ec` |
| `translate-c` | `2.0.0` @ `0da7a16c3235b935b82421646076e0657cda21f6` |

## Toolchain

| Field | Value |
|---|---|
| Zig | `0.17.0` (`minimum_zig_version` in `build.zig.zon`) |
| Rust (i686 asset only) | `i686-unknown-linux-musl` target |
| V8 | `zig-v8-fork` `b73e4fa2d0afe5036745ae7d332cc5cb7e7adb53`, V8 `15.5.35.13`, depot_tools `15.5.35.13` |
| Build host | Debian trixie container, `docker` |
| glibc→musl shim | [`build/musl_glibc_shim.c`](build/musl_glibc_shim.c) — one unconditional shim for both arches |
| i386 patches | [`patches/`](patches/) — V8 GN args + the 32-bit port (base commit `f734e7f`) |

## Released assets

| Asset | Arch | SHA-256 |
|---|---|---|
| `lightpanda-1.0.1-main.20261018-r2-x86_64-musl` | x86_64 | `605f2e2a2f748438dd9889634280479c7076410a635235db1400e55471d78b5a` |
| `lightpanda-1.0.1-main.20261018-r2-i686-musl` | i386 (32-bit x86) | `84eb5f92ce6fe8e61bd1bd030267790fae878a8a5356c3f86c2bc91d2f02e16c` |
| `lightpanda-1.0.1-main.20261018-r1-x86_64-musl` (historical) | x86_64 | `bbf780f79fc1102dd9a1efdbf2847e92f0fecd3dd74416ffc0eed83626a05f16` |
| `lightpanda-1.0.1-main.20261018-r1-i686-musl` (historical) | i386 (32-bit x86) | `def6f4ff9e22f67865267f2a00800f2361badc2bc65e65f5dd95b2e767296e74` |

`sha256sum -c SHA256SUMS` after downloading both assets.

Both hashes were re-verified on the test hosts themselves (`sha256sum` run against the
executable that was actually exercised), so the published bytes are the tested bytes.

## CPU requirement: SSE2 (verified)

V8's ia32 build refuses to start without SSE2 — on a Pentium III-class CPU (`qemu-i386
-cpu pentium3`) it aborts with:

```
Fatal error
Check failed: cpu.has_sse2().
```

So the real floor is **SSE2-class: Pentium 4 / Athlon 64 / Core Duo and newer**, not
"CMOV/MMX Pentium Pro" as earlier notes claimed. Confirmed working on a Core Duo L2500
(Yonah); 80386/486/Pentium/Pentium II/III are out.

## Reproducibility status

### Current release `r2` — CI-built and reproducible (2026-11-06)

`.github/workflows/build-release.yml` on the self-hosted runner builds each architecture
twice, from separate scratch dirs with cold zig caches, and the run fails unless the
**stripped** binaries are byte-identical:

| Asset | SHA-256 (stripped) | Size |
|---|---|---|
| `lightpanda-1.0.1-main.20261018-r2-x86_64-musl` | `605f2e2a2f748438dd9889634280479c7076410a635235db1400e55471d78b5a` | 75,973,544 B |
| `lightpanda-1.0.1-main.20261018-r2-i686-musl` | `84eb5f92ce6fe8e61bd1bd030267790fae878a8a5356c3f86c2bc91d2f02e16c` | 72,440,116 B |

Build inputs for `r2` (also in the release's `BUILDINFO.txt`): image
`sha256:41195f9be65bb3325c3b33b9876bfbd654bc9aba8be0fb33095310d90e499c9a`, built from
`build/Dockerfile` with base `debian:trixie@sha256:9c6e3814…` and Rust pinned to 1.99.1.

A separate check of the same recipe (fresh image + fresh clone + only the published patches)
reproduced the historical i686 builder output exactly (`84eb5f92…`).

The published patch set was validated against upstream's own gates on `f734e7f`:
`make test` → **1898/1898 passed, 7 skipped**; `zig fmt --check` clean. That run found one
test-only bug in the patch (a `.swap(0, .acq_rel)` call site left on the 32-bit atomics shim),
which is fixed in `patches/0002`; the release binaries are unaffected (`605f2e2a…` reproduced
byte-identically from the corrected tree).

### Historical `r1` — not reproducible

Rebuild experiments on the original builder, all from `f734e7f` with the pinned
`libc_v8_musl.a` and Zig `0.17.0`:

| Build | Tree path | SHA-256 (unstripped) |
|---|---|---|
| released `x86_64` asset | `/build/src/browser` (image of 2026-10-18 ~13:37) | `bbf780f79fc1…` |
| rebuild A | `/repro/browser` | `7f60e0505155…` |
| rebuild B | `/build/src/browser` | `c0932e9cb79c…` |
| rebuild C | `/build/src/browser` | `6d366b31fc0b…` |
| rebuild D | `/build/src/browser` | `70da24ffb17d…` |

**Codegen is deterministic; debug info is not.** Rebuilds C and D used identical inputs, the
same path and fresh caches: the unstripped binaries differ (`6d366b31…` vs `70da24ff…`, both
exactly 208,882,192 B) but their **stripped** hashes are identical. Only `.debug_info`,
`.debug_str` and `.debug_line` differ — hence stripped releases.

The `r1` `i686` asset matched the builder's own output exactly (`def6f4ff…`). The `r1`
`x86_64` asset did not reproduce from any rebuild: it was built in an earlier container image,
and the `lp-musl` image used for the i686 build was created at 15:19 the same day, after that
build. Releases from `r2` onward do not depend on an unpreserved image.

Practical consequences:

- **Verify integrity with `SHA256SUMS`, not by rebuilding.**
- To make this fully reproducible: pin the build image **by digest**, and publish
  **stripped** binaries — stripped output is stable across runs, unstripped is not.

### Link inputs (for anyone re-running this)

| Archive | SHA-256 |
|---|---|
| `libc_v8_musl.a` (x86_64, shim folded in) | `212974a2df03716198444866752b99ce67acb18b0d02118c6bb033abd5f53849` |
| `libc_v8_musl_ia32.a` (i686, shim folded in) | `a7cb9e51591af85070ab76da98860a55dcfc2b0687f4d23ced7929b6e9d78d9c` |

Toolchain in the image used for the `i686` build: Zig `0.17.0`, rustc `1.99.1`,
Debian clang `19.1.7`.
