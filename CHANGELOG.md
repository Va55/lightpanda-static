# Changelog

## v1.0.1-r1 — release naming fix

**No source or binary change.** The x86_64 and i686 assets are byte-identical to the
previous `v1.1.0-dev` release; only the tag and asset names changed.

### Why the rename

The previous names were taken from `lightpanda version`, which prints `1.1.0-dev`. That
string is **not** a release identifier: it is the *next development* version declared in
upstream's `build.zig.zon`, and upstream tags `1.0.1`, `1.0.2` and `1.0.3` all carry it.
Naming assets after it means three different browsers end up with interchangeable names,
and the "1.1.0" implies a release that does not exist.

### New scheme

`<upstream tag>-r<build revision>`, e.g. `lightpanda-1.0.1-r1-x86_64-musl`.

- Upstream tag the binary was built from: `1.0.1` (`99edca45844b5968c3ec8e50ad8e1acec8f3b759`)
- `-r1` is this project's build revision for that tag; bump it on any rebuild
- Full pins in [VERSIONS.md](VERSIONS.md)

### Docs

- `README.md`: release table now states the upstream tag; added the version-string note
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
