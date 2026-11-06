# Verifying a download

Everything here is checkable without trusting this repository's prose. If any step
below fails, treat the download as untrusted and open an issue.

## 1. Integrity and provenance (recommended)

```sh
tag=v1.0.1-main.20261018-r2
asset=lightpanda-${tag#v}-x86_64-musl

gh release download "$tag" --repo Va55/lightpanda-static   # both binaries + SHA256SUMS + BUILDINFO.txt
sha256sum -c SHA256SUMS                                    # bytes match the committed checksums
gh attestation verify "$asset" --repo Va55/lightpanda-static
```

What each step means:

| Step | What it proves |
|---|---|
| `sha256sum -c SHA256SUMS` | the file is the one described by `SHA256SUMS`, which is committed in this repo |
| `gh attestation verify` | the same digest carries a Sigstore build-provenance attestation produced by this repo's `attest-release` workflow, logged in the public transparency log |

The attestation is a SLSA v1 provenance statement whose subject is the asset digest and
whose builder is this repository's `.github/workflows/build-release.yml` at
`refs/heads/main`. Since `r2` that workflow **compiles** the binaries (it is not merely
attesting an upload), and it builds them twice, failing the run unless both passes produce
byte-identical stripped binaries. The release itself also carries GitHub's own release
attestation, which immutable releases create automatically.

`gh attestation verify` needs **gh ≥ 2.49**; on an older client you can at
least confirm an attestation exists for the digest (existence only — use a recent `gh` or
`cosign` to verify the signature):

```sh
gh api "repos/Va55/lightpanda-static/attestations/sha256:$(sha256sum "$asset" | cut -d' ' -f1)"
```

`BUILDINFO.txt` (attached to each release) lists every input: source commits, V8 archive
hashes, shim and patch hashes, build-image digest and zig/rustc/clang versions.

The attestation is created by `.github/workflows/attest-release.yml`, which **only
attests files that match the `SHA256SUMS` in the checked-out commit** — so the chain is
`protected main → SHA256SUMS → published asset → attestation → your download`.

Releases are marked **immutable** on GitHub (assets cannot be replaced or deleted) and the
`v*` tags are protected by a ruleset (no force-push, no deletion), so the coordinates in the
commands above can't be silently repointed.

## 2. It is really static, and really 32-bit on i386

```sh
file lightpanda-*-x86_64-musl    # ELF 64-bit LSB executable, x86-64, statically linked
file lightpanda-*-i686-musl      # ELF 32-bit LSB executable, Intel i386, statically linked
readelf -h lightpanda-*-i686-musl | grep Machine     # Intel 80386
readelf -d lightpanda-*-i686-musl | grep -c NEEDED   # 0
```

`ldd` is deliberately not used: on Alpine it prints `… Not a valid dynamic program` rather
than the glibc wording.

## 3. It runs and does real work

```sh
lightpanda version                                   # -> 1.1.0-dev (upstream's string, see README)
lightpanda fetch --dump semantic_tree_text https://example.com
lightpanda run script.js                             # exercises the JS engine
```

Hardware floor: **SSE2**. On x86_64 that is universal; for the i686 asset V8 aborts without
it (`Check failed: cpu.has_sse2()`), so Pentium II/III are out — Pentium 4, Athlon 64 and
Core Duo work.

## 4. Rebuilding

Read [VERSIONS.md](VERSIONS.md) first — reproducibility differs per asset, and that is
stated there with measured evidence rather than claimed.

```sh
docker build -t lp-musl build/            # environment in build/Dockerfile, versions in build/toolchain.lock

git clone https://github.com/lightpanda-io/browser          src/browser
git -C src/browser checkout f734e7f6aebc945fb8340284bfddd43244bf49ff
git clone https://github.com/lightpanda-io/zig-v8-fork      src/v8
git -C src/v8 checkout b73e4fa2d0afe5036745ae7d332cc5cb7e7adb53

git -C src/v8      apply "$PWD"/patches/0001-zig-v8-fork-ia32-gn-args.patch
git -C src/browser apply "$PWD"/patches/0002-lightpanda-ia32-port.patch

# fold the shim into the V8 archive (one unconditional shim, both arches)
zig cc -target x86_64-linux-musl -O2 -c build/musl_glibc_shim.c -o shim.o
ar r libc_v8_musl.a shim.o

# x86_64
cd src/browser && zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseFast \
  -Dprebuilt_v8_path=<abs path>/libc_v8_musl.a
```

Status, stated plainly:

- **`r2` assets are reproducible and CI-built.** The workflow builds each architecture twice
  with cold caches and fails unless the stripped bytes match; the published i686 hash also
  equals the historical builder output (`84eb5f92…`), so the published patches are complete.
- **`r1` assets are not reproducible** — built before CI existed, in a container image that
  was not preserved. Kept for lineage only.
- **Debug info is not bit-stable** even with identical inputs; **stripped** output is. That is
  why releases are stripped.
- **V8's own build is not verified reproducible.** The linked `libc_v8_*.a` archives are
  rebuilt only when absent from the cache; their hashes are recorded in `BUILDINFO.txt`, so a
  mismatch would be visible, but V8 itself is not re-derived per release.

## 5. What is *not* verifiable yet

Published for honesty rather than hidden:

- Builds run on a **self-hosted runner**, so the attestation proves “this repo's workflow
  compiled these bytes in this run”, not “a GitHub-hosted runner did”. The runner is one
  machine the maintainer controls; that is the same trust level as any project building on
  its own hardware, and it is visible in the provenance.
- **V8 is not rebuilt per release** — the linked archives come from a cache keyed by inputs,
  with their hashes recorded in `BUILDINFO.txt`.
- Single-maintainer project: no independent second-party build has been published yet.
- The `r1` assets cannot be rebuilt (missing build image).
