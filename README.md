# lightpanda-static

**Fully static** Lightpanda builds — pure-musl, and archiving **i386 (32-bit x86)** as well as
x86_64. "static" is the point: no glibc (and no libc-loader) needed at runtime, so they run on
any Linux regardless of distro (Alpine/musl, Debian/Ubuntu/glibc, distroless, …). The build
recipe that produces them is included.

Largest value is the **i386 (32-bit x86 / i686) port**: modern V8 engines dropped 32-bit support, but
this repo proves a usable browser can still be hand-built for one. The capability
toolchain (`target_cpu=x86` V8 + compat shim + sysroot) carries directly to an i386
Chromium should that ever be needed.

## Releases

The binaries are too large to commit (GitHub's 100 MB/file limit), so they ship as
**GitHub Releases** — statically-linked musl, archived per architecture:

| Asset | Arch | Size | Built from |
|-------|------|------|------------|
| `lightpanda-1.0.1-main.20261018-r1-x86_64-musl` | x86_64 | ~199 MiB | `main` @ `f734e7f` |
| `lightpanda-1.0.1-main.20261018-r1-i686-musl`   | i386 (32-bit x86) | ~170 MiB | `main` @ `f734e7f` |

Releases are named `<release line>-r<build revision>`. They are deliberately **not** named
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
| Alpine 3.24, 8 GB | Core 2 Duo E6550 @ 2.33 GHz, 2 cores | `x86_64` | 0.63 s | 1.24 s | 32–49 MB |
| Alpine 3.24, 3.2 GB | Core Duo L2500 @ 1.83 GHz, 2 cores | `i686` | 0.70 s | 1.27 s | 30–42 MB |

Both are 2-core, no-HT machines from 2006–2007, so this is roughly the worst case that
still runs a modern JS engine. JS execution was verified on the 32-bit host via
`lightpanda run` (arithmetic, `reduce`, string handling and IEEE-754 double formatting all
correct), which exercises V8's JIT on ia32.

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
