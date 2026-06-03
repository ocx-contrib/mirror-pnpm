# Stable smoke test — assert on the contract (exit code, version shape,
# functional side-effect), never on help/version prose. pnpm rewords its
# banners and help freely; the version digits and a working `init` are the
# contract.
#
# Tier 1 (--version exit 0) already proves the sibling `dist/` directory
# installed correctly: the root `pnpm` launcher loads dist/pnpm.cjs relative
# to itself, so a missing dist/ would fail before any output.
PNPM = "pnpm.exe" if ocx.target_platform.os == ocx.os.Windows else "pnpm"

# Tier 1 + 2: liveness + version SHAPE (semver digits, not a "pnpm" wordmark).
r_version = ocx.run(PNPM, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# Tier 3: functional side-effect. `pnpm init` boots the embedded Node runtime,
# runs the init command, and writes a package.json into scratch — a far
# stronger liveness proof than --version, which short-circuits before real
# init. No network: init scaffolds locally.
r_init = ocx.run(PNPM, "init")
expect.ok(r_init)
expect.true(ocx.exists("package.json"))
manifest = ocx.read_file("package.json")
expect.contains(manifest, "\"name\"")
