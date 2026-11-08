# The i386 (i686) patch set

> **Archived.** These patches are the source delta behind the frozen `r3` release and are
> kept for reference (and for anyone upstreaming them). They are not tracked forward against
> upstream `main` any more — see the freeze rationale in [../README.md](../README.md).

The two patches that make Lightpanda build for 32-bit x86, extracted from the trees the
released binaries were actually built from.

| Repo | Base commit | Patch |
|---|---|---|
| `lightpanda-io/zig-v8-fork` | `0c73cd1732df59b34f4fe4105edba74c42604f3a` (current pin; also applies to `b73e4fa2`, the pin used for the released `r2` binaries) | `0001-zig-v8-fork-ia32-gn-args.patch` |
| `lightpanda-io/browser` | `8678e04c4f87` (upstream `main`, 2026-11-06 — rebased) | `0002-lightpanda-ia32-port.patch` |

`0002` was rebased onto current `main` (`8678e04`, 2026-11-06) and validated there against
upstream's own gates — `make test` → **2295 of 2295 passed, 7 skipped**; `zig fmt --check`
clean. The released `r2` binaries were built from the earlier base `f734e7f` (the `1.0.1`
line + 91 commits); see [../VERSIONS.md](../VERSIONS.md).

## Apply

```sh
git -C zig-v8-fork apply 0001-zig-v8-fork-ia32-gn-args.patch
git -C browser      apply 0002-lightpanda-ia32-port.patch
```

Then build per [../build/README.md](../build/README.md). No patch is needed for the
x86_64 build.

## 0001 — V8 GN args for 32-bit (7 lines)

Adds an `arch == .x86` arm to `GnArgs` in `zig-v8-fork/build.zig`:

```
target_cpu="x86"
v8_enable_pointer_compression=false
v8_enable_sandbox=false
treat_warnings_as_errors=false
```

Without it, `-Dtarget=x86-linux-musl` never reaches V8's own compile and you silently get
an x86_64 V8. Pointer compression and the sandbox are 64-bit-only designs; both must be
off for a real ia32 build.

## 0002 — the 32-bit port itself (17 files, +113/−47)

Two groups of changes:

1. **`build.zig` — the `-Dcargo_target` option.** `linkRust` gains a build option that
   passes `--target <triple>` to cargo and reads the archive from
   `<target-dir>/<triple>/<profile>/` instead of the host `release/` path. Without it, the
   x86_64 Rust archive gets linked into the i386 executable
   (`is incompatible with elf_i386`).
2. **The port proper.** New `src/atomic_u64.zig` (u64 atomics over `std.atomic.Value(u32)`,
   since 64-bit atomics don't exist on 32-bit Zig), plus fixes in `Watchdog.zig`,
   `browser/js/Env.zig`, `Integer.zig`, `Snapshot.zig`, `TaggedOpaque.zig`,
   `EventManagerBase.zig`, `Inspector.zig`, `RecyclingAllocator.zig`, `log.zig`,
   `string.zig`, `network/header_parser.zig`, `network/http.zig`, `server/WS.zig`,
   `sys/libcurl.zig` and `webapi/webcodecs/VideoFrame.zig` — the usual `usize`-is-32-bits
   class of bugs: alignment assumptions, `1 << 48` tagged pointers, SWAR masks built from
   `@sizeOf(usize)`, `maxInt(usize)` caps, `curl_off_t != c_long` on i386.

## The shim is one file for both architectures

[`../build/musl_glibc_shim.c`](../build/musl_glibc_shim.c) is used unchanged for x86_64
**and** i686 — its sha256 is what both released binaries were linked with, and the i686
binary exports the shim's `mmap64`/`open64`/`fopen64`/`stat64`/`readdir64`. The LFS `*64`
block must stay **unconditional**: i686 musl does not export those either, and Rust's
`i686-unknown-linux-musl` std references them, so a `#if defined(__x86_64__)` guard fails
the link with `undefined symbol: fopen64`.
