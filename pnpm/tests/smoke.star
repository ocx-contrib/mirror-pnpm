# pnpm/tests/smoke.star — asserts the contract, never prose. Stable across
# upstream pnpm releases: a version SHAPE and computed results, no help text,
# no banner, nothing upstream may reword.

PNPM = "pnpm.exe" if ocx.target_platform.os == ocx.os.Windows else "pnpm"

# pnpm writes a global store, a config file and a cache under $HOME (or
# $PNPM_HOME / the XDG dirs). Point every one at the sandbox so the test never
# touches the runner's real home — and so it still works in a bare container
# image, where $HOME may be unset or unwritable. USERPROFILE is the Windows
# spelling; setting both keeps one dict for all platforms.
#
# Every command below is offline — verified under `docker run --network none`.
# Nothing here resolves a package, so the npm registry is never contacted.
ENV = {
    "HOME": ocx.scratch_root,
    "USERPROFILE": ocx.scratch_root,
    "PNPM_HOME": ocx.scratch_root,
    "XDG_CACHE_HOME": ocx.scratch_root,
    "XDG_CONFIG_HOME": ocx.scratch_root,
    "XDG_DATA_HOME": ocx.scratch_root,
}

# Tier 1 + 2: liveness on the composed PATH + semver version SHAPE (digits, not
# a "pnpm" wordmark). Reaching any output at all already proves the sibling
# `dist/` tree installed alongside the launcher: `pnpm` is a Node SEA that
# resolves dist/pnpm.mjs RELATIVE TO ITSELF, so a bundle that dropped dist/ —
# or buried the binary under a stripped wrapper directory — dies before
# printing.
r_version = ocx.run(PNPM, "--version", env = ENV)
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# Tier 3: functional side-effect. `init` boots the embedded Node runtime and
# writes a real manifest into scratch — a far stronger liveness proof than
# --version, which short-circuits before the runtime does any work.
r_init = ocx.run(PNPM, "init", env = ENV)
expect.ok(r_init)
expect.true(ocx.exists("package.json"))
expect.contains(ocx.read_file("package.json"), "\"name\"")

# Replace the generated manifest with a minimal one before any further command.
# `pnpm init` writes `devEngines.packageManager` with `"onFail": "download"`,
# and every later pnpm command then verifies that declaration against
# registry.npmjs.org — measured under `docker run --network none`:
#
#   pnpm pkg set name=…  → [ERROR] GET https://registry.npmjs.org/pnpm: fetch
#                          failed  (rc=1)
#
# A container leg has no reason to have working egress, so leaving init's
# manifest in place would make this test measure the network instead of pnpm.
ocx.write_file("package.json", "{\"name\": \"seed\", \"version\": \"1.0.0\"}\n")

# Tier 3: computed round-trip through pnpm's config layer, ending in a value
# pnpm DERIVES rather than echoes.
#
# NOT `pnpm pkg set/get`: that subcommand does not exist across this mirror's
# whole range. Measured on the real linux-x64 binaries, 2026-08-02 —
#
#   11.1.0  pkg set → rc=1  [ERR_PNPM_NOT_IMPLEMENTED] The "pkg" command is
#                            not yet implemented in pnpm. Use the npm CLI
#                            directly: npm pkg
#   11.2.0  pkg set → rc=1  (same)
#   11.3.0  pkg set → rc=0  ← first release carrying it
#
# — and this spec's floor is 11.1.0, so the backfill reddened every leg on
# 11.1.x/11.2.x, on darwin and windows too. `config set`/`config get`/`store
# path` all answer rc=0 on 11.1.0 through 11.11.0.
#
# `store path` is the assertion that carries weight: it is not the string we
# handed in, it is the store root pnpm resolves FROM that config value, with
# its own `/v11` layout suffix appended. A stub that merely records and replays
# the setting cannot produce it.
STORE = ocx.scratch_root + "/ocx-smoke-store"

r_set = ocx.run(PNPM, "config", "set", "store-dir", STORE, env = ENV)
expect.ok(r_set)
r_get = ocx.run(PNPM, "config", "get", "store-dir", env = ENV)
expect.ok(r_get)
expect.contains(r_get.stdout, "ocx-smoke-store")

r_store = ocx.run(PNPM, "store", "path", env = ENV)
expect.ok(r_store)
expect.contains(r_store.stdout, "ocx-smoke-store")
expect.matches(r_store.stdout, r"ocx-smoke-store[\\/]v\d+")
