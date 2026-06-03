# mirror-pnpm

OCX mirror for [pnpm](https://github.com/pnpm/pnpm). Publishes GitHub
releases to `ocx.sh/pnpm` with cascade tags after a smoke test per
`(version, platform)`.

Tracks the **v11** release line (archive format, `pnpm` binary + sibling
`dist/`). v10 used a different, incompatible single-binary format; a mirror
follows one line.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror.yml` | hand | `ocx-mirror pipeline generate ci` |
| `tests/smoke.star` | hand | — |
| `metadata*.json`, `CATALOG.md`, `logo.*` | hand | — |
| `.github/workflows/*.yml` | generated | re-run when `mirror.yml` changes |

CI fails on drift via `ocx-mirror pipeline generate ci --check`.

## Platform rollout

Pass 1 ships `linux/amd64` + `linux/arm64`. darwin (`arm64` only — pnpm v11
dropped macOS Intel at 11.1.0) and windows (`amd64` + `arm64`) are staged as
comments in `mirror.yml`; uncomment the matching `assets:` and `platforms:`
blocks, then `ocx-mirror pipeline generate ci`.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_MIRROR_REGISTRY_TOKEN` + `OCX_MIRROR_REGISTRY_USER` | `ocx package push` to `ocx.sh` |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of
scope; see [`NOTICE.md`](NOTICE.md).
