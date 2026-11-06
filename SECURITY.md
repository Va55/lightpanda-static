# Security policy

## What this repository ships

- Two statically linked Lightpanda binaries (GitHub Releases), derived from
  [lightpanda-io/browser](https://github.com/lightpanda-io/browser) and therefore
  **AGPL-3.0**.
- A glibc→musl compatibility shim (`build/musl_glibc_shim.c`) and the i386 port patch set
  (`patches/`) — **MIT**.

## Reporting a vulnerability

Please do **not** open a public issue for a security problem.

- Preferred: GitHub private vulnerability reporting —
  <https://github.com/Va55/lightpanda-static/security/advisories/new>
- If that is unavailable to you, open an issue with no details asking for a private channel.

Useful in a report: the affected asset and its SHA-256, the platform, whether the issue is in
**Lightpanda/V8 upstream** or in **this repo's artifacts** (shim, patches, packaging,
verification instructions), and a minimal reproduction.

## Scope

In scope:

- `build/musl_glibc_shim.c`, `patches/`, `build/Dockerfile`
- The released binaries' packaging and integrity (checksums, attestations, release
  immutability, tag protection)
- Incorrect or misleading verification guidance in `VERIFY.md`

Out of scope here (report upstream, and tell us if the shipped binaries are affected):

- Bugs and vulnerabilities in Lightpanda itself or in V8 —
  <https://github.com/lightpanda-io/browser/security>
- Vulnerabilities reachable only through page content that the upstream project already
  documents as unsupported

## Known hardening differences from a stock upstream build

These are deliberate and documented, but they are security-relevant, so they are stated
here rather than buried in the build notes:

| Difference | Effect |
|---|---|
| Shim routes glibc fortify `__*_chk` calls to the plain libc functions | **no fortify hardening** |
| i686 build disables V8's sandbox and pointer compression (`v8_enable_sandbox=false`, `v8_enable_pointer_compression=false`) | 64-bit-only mitigations absent on 32-bit |
| `backtrace*` implemented over `_Unwind_Backtrace` | diagnostic only; symbolization differs |
| V8 ia32 requires SSE2; no AVX on either build | codegen mitigations (e.g. CET/SHSTK) are whatever Debian's clang emits |

**Treat any page content processed by these binaries as untrusted.** They are browsers, with
a JavaScript engine (JIT) exposed to attacker-controlled input.

## Verification of releases

Releases are immutable, `v*` tags are protected by a ruleset, and every release carries a
Sigstore build-provenance attestation. See [VERIFY.md](VERIFY.md).
