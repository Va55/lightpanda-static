# Revival policy — when a frozen project may build again

`r3` (`v1.0.3-main.20261106-r1`) is the final artifact. That does not mean the project can never
build again: it means **a rebuild has to be earned by functionality, not by a version number**.

Upstream ships tags every couple of weeks (1.0.0 → 1.0.3 in five weeks) and a few hundred
commits a day. Almost none of that is a reason to rebuild a 32-bit browser: fixes, refactors,
perf work, CI, docs, and dependency bumps all leave the proof exactly as proven. What *would*
justify a new release is a change in what the browser can **do** — a new engine, new protocol
surface, new web APIs.

So the trigger is functional, and it is mechanical enough to be checked rather than argued
about.

## Status vocabulary

| Term | Meaning |
|---|---|
| **The artifact is frozen** | `r3` and its attestation are immutable and will never be replaced. |
| **The project is dormant** | No routine releases. It revives only when a trigger below fires. |
| **A revival** | A new release line built from a new upstream base, following the same gates as `r2`/`r3`. |

## Trigger classes

A **trigger** is any one of these. It opens a *review*, never a release.

**T1 — engine.** The V8 pin in upstream `build.zig.zon` is no longer
`0c73cd1732df59b34f4fe4105edba74c42604f3a` (the pin `r3` shipped). A new engine is the single
strongest functional reason to rebuild, and it is also the biggest risk to the ia32 port.

**T2 — capability.** **≥ 3 additive** feature commits since the `r3` base (`8678e04`) — subjects
prefixed `cdp:`, `webapi:`, `js:`, `dom:`, `agent:` that use an additive verb
(`add`, `implement`, `support`, `introduce`, `new`, `expose`, `enable`). New CDP domains are the
clearest example: they change what Puppeteer/Playwright can drive.

**T3 — curated release notes.** A new upstream tag *whose notes describe new capability*. The tag
is only a **pointer to the notes**, not the trigger; a patch release full of fixes is not a
reason to rebuild.

## Explicit non-triggers

`fix:`, `perf:`, refactors, dependency bumps (other than V8), `test:`, `ci:`, docs, `nix:`,
`tools:`, `orderfile:`, commit count, elapsed time, and "a new version number exists". None of
these change what the binary can do, and rebuilding for them is how an archived proof turns
back into a maintenance job.

## Kill condition (stated in advance)

If upstream removes ia32 from V8 or drops `target_cpu="x86"` support, the archive is **final**.
No trigger can fire; this document becomes a note rather than a plan. The same applies if the
patch set stops applying and the fix is no longer bounded (see cost below).

## The process, when a trigger fires

1. **Decide it is functional** — read the radar digest; confirm it is capability, not churn.
2. **Rebase the patches** onto the new base: `patches/0001` (7 lines, GN args) then
   `patches/0002`. Expect small mechanical hunks; budget a session because a real upstream
   change can break the port (that is how the webaudio `usize` bug was found).
3. **Gate it**: `make test` (must be all-pass; `r3` was 2295/2295, 7 skipped) and
   `zig fmt --check ./*.zig ./*/*.zig`.
4. **Build twice with cold caches** in CI; publish only if the stripped output is byte-identical
   across passes. Measured: **25 minutes** wall clock on `zen2` (both passes + attestation).
5. **Attest, release immutably, and update the record**: `VERSIONS.md` (base commit, V8 pin,
   hashes, sizes), `CHANGELOG.md`, README table, landing page. Then re-run hardware validation on
   the i686 laptop and an x86_64 box — hashes alone do not prove the thing runs.

The publish job in `build-release.yml` is deliberately guarded with `exit 1`: a revival is a
commit that removes that guard **and** updates this document. That keeps a workflow run from
quietly becoming a release.

## Watchdog

`~/bin/revival-radar.sh` (weekly cron) implements T1–T3 above and writes a digest to
`~/.cache/revival-radar/radar.md`. Only when a trigger set fires does it write
`~/REBUILD-CANDIDATE.md`. It is a prompt to a human, not an automation: nothing in it can
publish anything.
