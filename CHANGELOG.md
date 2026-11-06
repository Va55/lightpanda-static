# Changelog

## v1.0.1-main.20261018-r1 — release naming fix

**No source or binary change.** The x86_64 and i686 assets are byte-identical to the
original `v1.1.0-dev` release; only the tag and asset names changed.

Rename history, for the record: `v1.1.0-dev` → `v1.0.1-r1` → **`v1.0.1-main.20261018-r1`**.

### Why the rename

The original names were taken from `lightpanda version`, which prints `1.1.0-dev`. That
string is **not** a release identifier: it is the *next development* version declared in
upstream's `build.zig.zon`, and upstream tags `1.0.1`, `1.0.2` and `1.0.3` all carry it.
Naming assets after it means three different browsers end up with interchangeable names,
and the "1.1.0" implies a release that does not exist.

`v1.0.1-r1` was then found to be imprecise as well: the binaries were not built from the
`1.0.1` tag but from `main` at `f734e7f`, **91 commits after** that tag. Hence the current
name.

### Scheme

`<release line>-main.<yyyymmdd>-r<build revision>`, e.g.
`lightpanda-1.0.1-main.20261018-r1-x86_64-musl`.

- Release line: `1.0.1`; exact build commit: `f734e7f6aebc945fb8340284bfddd43244bf49ff`
  (upstream `main`, 2026-10-18 = the `20261018` part)
- `-r1` is this project's build revision for that commit; bump it on any rebuild
- Full pins in [VERSIONS.md](VERSIONS.md)

### Docs

- `README.md`: release table now states the build commit; added the version-string note
  explaining why `lightpanda version` disagrees with the asset name.
- `README.md` / `build/README.md`: `Verify` block corrected — `version` prints
  `1.1.0-dev` (not `Lightpanda 1.1.0-dev`), `ldd` replaced with `file` + `readelf -d` (on
  Alpine, `ldd` prints "Not a valid dynamic program"), and `sha256sum -c SHA256SUMS` added.
- `VERSIONS.md`: new — pinned upstream commit, all dependency revisions, toolchain, asset
  hashes, and the known provenance gaps.

### Verification

Both assets were run on their native architecture and their SHA-256 matches `SHA256SUMS`
exactly (so the bytes published are the bytes tested):

| Asset | Host | CPU | `example.com` | Peak RSS |
|---|---|---|---|---|
| `x86_64` | Alpine 3.24, 8 GB | Core 2 Duo E6550 @ 2.33 GHz | 0.63 s | 32–49 MB |
| `i686` | Alpine 3.24, 3.2 GB | Core Duo L2500 @ 1.83 GHz | 0.70 s | 30–42 MB |

JS execution confirmed on the 32-bit host with `lightpanda run` (V8 ia32 JIT), including
IEEE-754 double formatting. Pre-SSE2 CPUs remain untested.

### Corrections after publication

- **Build commit pin corrected.** Earlier notes said these binaries came from upstream tag
  `1.0.1`. The build tree was in fact a shallow clone of `main` at
  `f734e7f6aebc945fb8340284bfddd43244bf49ff` (2026-10-18) — **91 commits after tag `1.0.1`**.
  Asset names and bytes are unchanged; only the documentation is corrected.
- **ISA floor confirmed: SSE2.** `qemu-i386 -cpu pentium3` aborts at V8's own probe with
  `Check failed: cpu.has_sse2()`. The earlier "CMOV/MMX, i.e. Pentium Pro" claim was wrong:
  the floor is Pentium 4 / Athlon 64 / Core Duo class.
- **i386 source delta published** in [`patches/`](patches/): the V8 GN-args patch and the
  17-file 32-bit port (+113/−47), extracted from the build trees, plus V8/depot_tools
  `15.5.35.13` recorded in `VERSIONS.md`.
- **Shim clarified**: one *unconditional* shim serves both architectures — verified from the
  i686 binary's exported `mmap64`/`open64`/`fopen64`/`stat64`/`readdir64`.

### Reproducibility measured

Four rebuilds on the original builder, all from `f734e7f` with the pinned V8 archive:

- **Codegen is deterministic, debug info is not.** Two same-input, same-path, fresh-cache
  rebuilds differ unstripped (`6d366b31…` vs `70da24ff…`) but are **byte-identical when
  stripped** (`5287049b…`); only `.debug_info`/`.debug_str`/`.debug_line` differ.
- **`i686` asset reproduced exactly**: the builder's own output hashes to `def6f4ff…`,
  identical to the published asset.
- **`x86_64` asset not reproducible**: its stripped hash is `ec13f643…`, which no rebuild
  reaches — it was built at 13:37 in an earlier container image; the `lp-musl` image used
  for the `i686` build was created at 15:19 the same day.

Consequence: verify integrity with `SHA256SUMS`, not by rebuilding. Full evidence, plus
the SHA-256 of both `libc_v8_*.a` link inputs, in [VERSIONS.md](VERSIONS.md).
