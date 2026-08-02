# mirror-pnpm

OCX mirror for [pnpm](https://github.com/pnpm/pnpm). One repository, one spec
directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [pnpm](https://github.com/pnpm/pnpm) | [`pnpm/mirror.yml`](pnpm/mirror.yml) | `ghcr.io/ocx-contrib/pnpm/pnpm` | `ocx.sh/pnpm/pnpm` | `MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

> This repository previously published the same upstream to the flat coordinate
> `ocx.sh/pnpm`. `pnpm/pnpm` is the grouped successor; upstream's owner *is*
> `pnpm`, so org and tool coincide.

Tracks the **v11** release line. v10 used a different, incompatible
single-binary format; a mirror follows one line.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
pnpm/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all.

## Platforms

Seven platform entries: **four** Linux keys, `darwin/arm64`, and both Windows
arches. Upstream ships a separate glibc and musl build per Linux arch and
**neither is static** — each carries a `PT_INTERP` naming its own loader — so
neither covers the other and all four Linux keys carry an explicit `+libc.*`
feature. The measurements are recorded above `pnpm/mirror.yml`'s `assets:`.

No `darwin/amd64`: upstream dropped `pnpm-darwin-x64.tar.gz` at v11.0.5, below
this spec's `11.1.0` floor.

### ⚠️ Known defect: the Linux builds do not start on a stock host

`os.features` states what an artifact requires of the host, and a `+libc.*`
key is the strongest claim it can make. For pnpm that key is **necessary but
not sufficient**. pnpm is a Node single-executable-application with a C++
runtime, so it needs shared objects no base image ships and `os.features` has
no vocabulary to name:

| Build | Missing on a stock host | Fix on the host |
|---|---|---|
| glibc (`pnpm-linux-{x64,arm64}.tar.gz`) | `libatomic.so.1` | `apt-get install libatomic1` / `dnf install libatomic` |
| musl (`pnpm-linux-{x64,arm64}-musl.tar.gz`) | `libstdc++.so.6`, `libgcc_s.so.1` | `apk add libstdc++` |

Measured on v11.19.0:

```
docker run ubuntu:24.04 <gnu>/pnpm  --version → libatomic.so.1: cannot open shared object file
docker run fedora:40    <gnu>/pnpm  --version → libatomic.so.1: cannot open shared object file
docker run alpine:3.20  <musl>/pnpm --version → Error relocating …: _ZSt4cout: symbol not found
docker run ubuntu:24.04 sh -c 'apt-get install -y libatomic1; <gnu>/pnpm --version'  → 11.19.0
docker run fedora:40    sh -c 'dnf install -y libatomic;      <gnu>/pnpm --version'  → 11.19.0
docker run alpine:3.20  sh -c 'apk add libstdc++;             <musl>/pnpm --version' → 11.19.0
```

The `+libc.*` keys themselves are correct, and the cross-checks prove it — each
build fails at exec under the other's loader (`sh: not found`, the loader
reporting a missing *interpreter*), so neither could carry a bare key.

**There is no spec mechanism to install those packages in a container leg.** A
`setup:` key on a container entry validates green and is then silently dropped
— the schema ignores unknown keys, and the rendered workflow contains no trace
of it. So **every Linux container leg is expected to red**, and the push gate
(AND across a platform's containers) will withhold all four Linux tiles. That
is the honest result rather than a weakened test: pnpm's published Linux builds
do not start on a stock ubuntu, fedora or alpine host. The fix belongs upstream
— static-link `libatomic`, or ship the runtime deps.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `pnpm/mirror.yml` | hand | yes — see below |
| `pnpm/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `pnpm/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec pnpm/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

pnpm's archive has **no wrapper directory** — `pnpm` and the sibling `dist/`
tree it loads relative to itself both sit at the archive root. So
`strip_components: 0` makes the content root the interface root and the bundle's
only PATH entry is a bare `${installPath}`; pointing it at `${installPath}/bin`
would break the `dist/` lookup. `bin_scan` only looks *below* an
`${installPath}/<dir>` entry, so `auto`/`verify` is rejected at spec load with
exit 65. `mirror-base.yml` therefore sets `bin_scan: off` and
`pnpm/metadata.json` hand-lists `binaries: ["pnpm"]` — the blessed shape here.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
