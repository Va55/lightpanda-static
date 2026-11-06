# Build provenance (pinned inputs)

What the released binaries were actually built from. The recipe is in
[build/README.md](build/README.md).

## Upstream

| Field | Value |
|---|---|
| Project | [lightpanda-io/browser](https://github.com/lightpanda-io/browser) |
| Tag | **`1.0.1`** |
| Commit | **`99edca45844b5968c3ec8e50ad8e1acec8f3b759`** |
| Upstream release date | 2026-10-15 |
| Version string inside the binary | `1.1.0-dev` |

`lightpanda version` prints `1.1.0-dev` because upstream's `build.zig.zon` at tag `1.0.1`
declares the *next development* version. Tags `1.0.1`, `1.0.2` and `1.0.3` all ship the
same string, which is why releases here are named after the **tag**, not the string.

```sh
git clone https://github.com/lightpanda-io/browser
git checkout 99edca45844b5968c3ec8e50ad8e1acec8f3b759   # tag 1.0.1
```

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
| Build host | Debian trixie container, `docker` |
| glibc→musl shim | [`build/musl_glibc_shim.c`](build/musl_glibc_shim.c) (this repo) |

## Released assets

| Asset | Arch | SHA-256 |
|---|---|---|
| `lightpanda-1.0.1-r1-x86_64-musl` | x86_64 | `bbf780f79fc1102dd9a1efdbf2847e92f0fecd3dd74416ffc0eed83626a05f16` |
| `lightpanda-1.0.1-r1-i686-musl` | i386 (32-bit x86) | `def6f4ff9e22f67865267f2a00800f2361badc2bc65e65f5dd95b2e767296e74` |

`sha256sum -c SHA256SUMS` after downloading both assets.

## Known provenance gaps

Stated plainly so nobody assumes more reproducibility than exists:

- The `-Dcargo_target` patch to `build.zig`'s `linkRust` (needed for the i686 Rust FFI) is
  described in `build/README.md` but is **not yet published as a patch file**.
- The ~40 i386 source fixes are listed as prose in `build/README.md`, not as diffs.
- No second independent build has been compared byte-for-byte, so the binaries are
  **not yet verified reproducible**.
