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

### Trust surface (2026-11-06)

What a consumer can now check, and what it rests on:

- **Immutable release.** Immutable releases are enabled on the repo, and this release was
  re-created so it is covered (`immutable: true`); asset bytes can no longer be replaced or
  deleted. Digests are unchanged (`bbf780f7…` / `def6f4ff…`).
- **Protected refs.** Two rulesets, both `enforcement: active` with **no bypass actors**
  (`current_user_can_bypass: never`): `main` (no force-push, no deletion) and `v*`
  (no update, no deletion, no force-push). An admin can still edit the ruleset itself —
  that is a GitHub property, not something a repo can remove.
- **Sigstore/SLSA provenance.** `.github/workflows/attest-release.yml` downloads a release,
  refuses to continue unless the files match the committed `SHA256SUMS`, then emits a SLSA v1
  attestation (keyless OIDC, transparency log). Verified produced for both digests, builder
  `…/.github/workflows/attest-release.yml@refs/heads/main`. Actions are pinned by commit SHA;
  Dependabot keeps them current.
- **Published environment.** `build/Dockerfile` + `build/toolchain.lock` (zig 0.17.0,
  rustc 1.99.1, clang 19.1.7, image digest, V8 archive hashes) instead of prose.
- **Verification + disclosure.** `VERIFY.md` (including an explicit "what is not verifiable
  yet") and `SECURITY.md` (private reporting, scope split, hardening differences).

## v1.0.1-main.20261018-r2 — CI-built, stripped, reproducible

First release built by CI rather than on an ad-hoc container.

- **`build-release.yml`** runs on the self-hosted runner (24 cores/30 GB — V8 needs it),
  builds each architecture **twice** with separate scratch dirs and cold caches, and fails the
  run unless the stripped binaries are byte-identical.
  - x86_64 `605f2e2a…` (75,973,544 B) · i686 `84eb5f92…` (72,440,116 B)
  - the i686 hash equals the historical builder output, so the published patches are complete
- **Stripped**: 72/69 MiB instead of 199/170 MiB, identical code.
- **Genuine build provenance**: the Sigstore/SLSA attestation is produced by the workflow that
  compiled the binaries (plus GitHub's own release attestation from immutable releases).
- **`build/ci-build.sh`** holds the build logic (auditable, versioned), `BUILDINFO.txt` ships
  with the release and records every input — commits, V8 archive hashes, shim/patch hashes,
  image digest, toolchain versions.
- `build/Dockerfile` now pins the base image by digest and Rust by version, since an unpinned
  `debian:trixie` + `stable` rust would drift and change the bytes.

Notes from getting it green: the runner's network DNS-filters `sigstore.dev` to a sinkhole
(`10.250.249.67` / `::1`, Whalebone CA), so the workflow resolves `fulcio`, `rekor` and
`tuf-repo-cdn` over DoH into `/etc/hosts` for the job and pre-flights them before signing.
The `gh` CLI must exist on the runner for the publish step (it now does).

`r1` stays published for lineage but was built before CI existed and is not reproducible.

### Corrected `patches/0002` — a bug found by upstream's own test suite

Running the upstream gates against the port (`make test`, `zig fmt --check`, their exact
commands) caught a real bug in the published patch: `src/Watchdog.zig`'s test still called
`.swap(0, .acq_rel)` after the 32-bit atomics shim dropped the ordering argument.

It sits inside a `test "Watchdog: …"` block, so it is compiled out of ReleaseFast builds —
which is why the release binaries were fine and only the test build broke. Verified rather
than assumed: rebuilding x86_64 ReleaseFast from the corrected tree yields
`605f2e2a…`, byte-identical to the published `r2` asset. **The `r2` assets stand; only the
patch file was wrong.**

With the corrected patch applied to `f734e7f`:

- `make test` — **1898 of 1898 tests passed, 7 skipped**
- `zig fmt --check ./*.zig ./*/*.zig` — clean
- patch applies cleanly to a pristine `f734e7f` and reverse-applies to the built tree

### `patches/0002` rebased onto current upstream main

`main` had moved a long way (`f734e7f` → `8678e04`, ~3 weeks), so the port was rebased. Three
hunks needed manual porting, all one-liners: upstream restructured the imports in `log.zig`
(ours re-added after `std`), `Env.zig`'s `stall_report_requested_at.store(0, .release)` →
`.store(0)`, and `Watchdog.zig`'s same call site (its test moved, so the hunk landed elsewhere).

Validated on the rebased tree against upstream's own gates:

- `make test` → **2295 of 2295 tests passed, 7 skipped** (with the `zig-v8-fork` / prebuilt
  V8 `v0.6.2` revision that current `main` pins — the pin moved since `r2`)
- `zig fmt --check ./*.zig ./*/*.zig` → clean
- `patches/0002` applies cleanly to a pristine `8678e04` clone
- `patches/0001` still applies cleanly to the currently pinned `zig-v8-fork` (`0c73cd1`)

Still outstanding for an i686 build off current `main`: the V8 ia32 archive has to be rebuilt
for the new `zig-v8-fork` pin; the published `r2` binaries remain built from `f734e7f`.

## 1.0.3-main.20261106-r1 — built from current upstream main

First release built from `main`@`8678e04` (tag `1.0.3` + 209 commits) rather than `f734e7f`, so
the binaries are finally aligned with the patch set that passes upstream's gates.

- x86_64 `be6ae67a…` (77,566,888 B) · i686 `1f0069d2…` (73,845,044 B), both passes identical
- Both V8 musl archives rebuilt for the pin `main` uses (`zig-v8-fork` `0c73cd17`, V8
  `15.5.35.13`); their hashes are in the release's `BUILDINFO.txt`
- `patches/0002` gained one fix the rebase turned up: upstream added webaudio, whose
  `OfflineAudioContext` used the u64 frame counter as a `usize` slice index
  (`@memcpy(out[start..][0..n], …)`) — a 32-bit-only compile error
- Gate evidence on the same base: `make test` 2295/2295, `zig fmt --check` clean

Two CI-path bugs were fixed along the way, both mine, both in `v8_mode=build`: the V8 archive
is no longer at `<repo>/out/...` but under `<repo>/.lp-cache/v8-<ver>/out/...`, so the script
searches the tree instead of guessing, and it now verifies the shim actually landed in the
archive (`zig ar t`) instead of assuming it.

Hardware validation: the `r3` i686 asset was run on the ThinkPad X60s (Core Duo L2500) —
hash matches the release, `example.com` 0.72–1.00 s, Wikipedia 1.34–1.61 s, 33–42 MB RSS, and
`lightpanda run` confirms the V8 ia32 JIT. The x86_64 asset was run on Debian 13/glibc and
reports `not a dynamic executable`, confirming the static-linking claim across distros.
