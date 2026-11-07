# lightpanda-static

> **STATUS: frozen — a capability demonstration, not a maintained target.**
>
> This project exists to prove that a usable browser with a modern JS engine can still be
> hand-built for **32-bit x86** in 2026, after every mainstream engine has dropped it. That
> goal was reached and archived at **`r3`** (`v1.0.3-main.20261106-r1`, 2026-11-07). The
> release, the reproducible-build record, and the hardware measurements below are frozen as
> the permanent record of the proof. **No further releases are planned.** The door closes
> from two sides: upstream V8's ia32 sunset (the engine), and the post-quantum TLS migration
> a frozen crypto stack can't ride (the networking/trust). Both point one way — this is a
> snapshot, not a maintained line.

**Fully static** Lightpanda builds — pure-musl, archiving **i386 (32-bit x86)** as well as
x86_64. "static" is the point: no glibc (and no libc-loader) needed at runtime, so they run on
any Linux regardless of distro (Alpine/musl, Debian/Ubuntu/glibc, distroless, …). The build
recipe that produces them is included.

Largest value is the **i386 (32-bit x86 / i686) port**: modern V8 engines dropped 32-bit support, but
this repo proves a usable browser can still be hand-built for one. The capability
toolchain (`target_cpu=x86` V8 + compat shim + sysroot) carries directly to an i386
Chromium should that ever be needed.

## Trust & verification

- **Verifiable downloads** — [VERIFY.md](VERIFY.md): checksums, static-ness proof, and
  `gh attestation verify`. Since `r2` the attestation is **build** provenance: created by the
  workflow that compiled the binaries, on a reproducible build (two identical passes).
- **Immutable releases**, protected `v*` tags (no force-push, no deletion), and `main`
  blocks force-push/deletion. Immutable releases also add a GitHub release attestation
  binding the release to its commit.
- **Published build environment** — [build/Dockerfile](build/Dockerfile) and
  [build/toolchain.lock](build/toolchain.lock); the exact upstream commit, dependency
  revisions and V8 archive hashes are in [VERSIONS.md](VERSIONS.md).
- **Known limits stated, not hidden** — the historical `r1` build is not reproducible, and
  only a self-maintained runner has the resources to build this. See *“What is not
  verifiable yet”* in [VERIFY.md](VERIFY.md).
- **Security policy** — [SECURITY.md](SECURITY.md), including the deliberate hardening
  differences (fortify `_chk` no-ops; V8 sandbox and pointer compression off on i386).

## Releases

> **`r3` is the final release.** The project is frozen after it (see the status banner above);
> the release and its attestation remain immutable and downloadable, but no new builds or
> versions will be cut.

The binaries are too large to commit (GitHub's 100 MB/file limit), so they ship as
**GitHub Releases** — statically-linked musl, archived per architecture:

| Asset | Arch | Size | Built by |
|-------|------|------|----------|
| `lightpanda-1.0.3-main.20261106-r1-x86_64-musl` | x86_64 | ~74 MiB | CI (`build-release.yml`) |
| `lightpanda-1.0.3-main.20261106-r1-i686-musl`   | i386 (32-bit x86) | ~70 MiB | CI (`build-release.yml`) |

Built from upstream `main` @ `8678e04` (2026-11-06) — tag `1.0.3` plus 209 commits — with the
`zig-v8-fork` / V8 revision that `main` pins. Assets are **stripped**; earlier releases are kept
for lineage but `v1.0.1-main.20261018-r1` predates CI and is not reproducible.

Builds run on a self-hosted runner (24 cores/30 GB — V8 needs that), from the pinned sources
in [VERSIONS.md](VERSIONS.md), **twice per release**; the workflow fails unless both passes
produce byte-identical stripped binaries.

Releases are named `<release line>-main.<yyyymmdd>-r<build revision>`. They are deliberately **not** named
after the version string the binary prints — see below.

> **Version-string note:** `lightpanda version` prints **`1.1.0-dev`**, which is *not* a
> release identifier. Upstream's `build.zig.zon` declares the *next* development version,
> and tags `1.0.1`, `1.0.2` and `1.0.3` **all** ship `.version = "1.1.0-dev"`, so naming
> assets after that string would make three different browsers interchangeable. Releases
> use the release line instead, and the **exact commit** is pinned in
> [VERSIONS.md](VERSIONS.md): `lightpanda-io/browser` `f734e7f6` — upstream `main`,
> 91 commits after tag `1.0.1` (which is `99edca45`).

> **Arch note:** the 32-bit asset file is named `i686` (its real ISA floor). "i386" is the
> human-facing label: that is how Debian and the ecosystem name 32-bit x86, and it's what
> the port is for. The floor is **SSE2** (Pentium 4 / Athlon 64 / Core Duo and newer), not
> i686/CMOV: V8's ia32 build aborts on anything without SSE2 — under
> `qemu-i386 -cpu pentium3` it fails with `Check failed: cpu.has_sse2()`. Verified working
> on a real Core Duo L2500 (Yonah).

## Install

```sh
sudo install -m 0755 <downloaded binary> /usr/local/bin/lightpanda
```

## Verify

```sh
lightpanda version        # -> 1.1.0-dev   (upstream next-dev string, see note above)
file /usr/local/bin/lightpanda                          # "... statically linked ..."
readelf -d /usr/local/bin/lightpanda | grep -c NEEDED  # -> 0
sha256sum -c SHA256SUMS   # integrity; SHA256SUMS ships with the release
lightpanda fetch --dump semantic_tree_text https://example.com
```

`lightpanda version` never initializes V8 (it returns in ~0.00 s at 2.5 MB RSS), so it only
proves the file executes — the `fetch` above is the real smoke test (~32 MB RSS).
`ldd` is avoided on purpose: on Alpine it prints
`/lib/ld-musl-x86_64.so.1: …: Not a valid dynamic program` rather than the glibc
"not a dynamic executable" wording.

## Tested on

Both assets were run on real 32-bit and 64-bit musl hosts, and the SHA-256 of each tested
file matches `SHA256SUMS` exactly.

| Host | CPU | Asset | `example.com` | Wikipedia article | Peak RSS |
|---|---|---|---|---|---|
| Alpine 3.24 (ThinkPad X60s), 3.2 GB | Core Duo L2500 @ 1.83 GHz, 2 cores | `1.0.3-main.20261106-r1` `i686` | 0.72–1.00 s | 1.34–1.61 s | 33 / 42 MB |
| Alpine 3.24, 8 GB | Core 2 Duo E6550 @ 2.33 GHz, 2 cores | `1.0.3-main.20261106-r1` `x86_64` | 0.53–0.54 s | 1.01–1.02 s | 37–52 MB |
| Debian 13 (glibc), 30 GB | — (24 cores) | `1.0.3-main.20261106-r1` `x86_64` | 0.34 s | 0.85 s | — |

The two Alpine rows are 2-core, no-HT machines from 2006–2007 — roughly the worst case that
still runs a modern JS engine. The Debian row matters for a different reason: the same
statically linked musl binary reports `not a dynamic executable` and runs unchanged on a
glibc distro, which is the point of static linking.

JS execution was verified on the 32-bit host via `lightpanda run` (arithmetic, `reduce`,
string handling and IEEE-754 double formatting all correct), exercising V8's JIT on ia32.
On the 32-bit box `r3` is marginally slower than `r2` (`lwn.net` 1.15 s → 1.6 s), while on
x86_64 it is faster (`example.com` 0.63 s → 0.53 s, Wikipedia 1.24 s → 1.01 s) — consistent with
~209 upstream commits: more feature code to load, better codegen on the 64-bit path.

## Build from source

Full toolchain and commands in [build/README.md](build/README.md), and the actual i386 source
delta in [patches/](patches/) (V8 GN args + the 32-bit port). The key built-in
ingredient is [build/musl_glibc_shim.c](build/musl_glibc_shim.c) — a small glibc-symbol
compat layer (`*64` LFS family, `__isoc23_*`, fortify `_chk`, `backtrace*`,
`__libc_stack_end`) folded into the V8 archive so Lightpanda links pure-musl. One
unconditional shim serves both architectures.

```sh
# x86_64
zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseFast \
  -Dprebuilt_v8_path=<libc_v8_musl.a, shim folded in>

# i686 (i386 port)
rustup target add i686-unknown-linux-musl
zig build -Dtarget=x86-linux-musl -Doptimize=ReleaseFast \
  -Dcargo_target=i686-unknown-linux-musl \
  -Dprebuilt_v8_path=<libc_v8_musl_ia32.a, shim folded in>
```

## License

This repo is dual-licensed — see [LICENSE](LICENSE) for the exact split:

- **Original code here** (the shim and build recipe) — **MIT**
- **The Lightpanda binaries** in the GitHub Releases — **AGPL-3.0**,
  a derivative of [lightpanda-io/browser](https://github.com/lightpanda-io/browser).
  They are NOT MIT-licensed. Corresponding source = upstream Lightpanda plus the
  modifications in this repo (see [build/README.md](build/README.md)).

## Related (same author, same 32-bit + musl stack)

Pair this browser with the agent-provisioning kit for the same i386 machines:
[Va55/hermes-i386](https://github.com/Va55/hermes-i386) runs **hermes-agent** on
i386 (32-bit x86) Linux, Debian & Alpine — a static headless browser and a working
agent on one i386 box.
