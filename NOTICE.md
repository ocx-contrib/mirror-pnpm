# NOTICE

This repository packages and redistributes upstream software published by the
[pnpm project](https://github.com/pnpm). The Apache-2.0 license in
[`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — each package's redistributed bytes
carry their own license, recorded below.

Each package's logo is reproduced for catalog identification only, under
nominative fair use. The marks remain the property of their respective owners
and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `pnpm` | `ghcr.io/ocx-contrib/pnpm/pnpm` | `MIT` |

---

## `pnpm`

Upstream: <https://github.com/pnpm/pnpm>
Published to `ghcr.io/ocx-contrib/pnpm/pnpm`.

| Component | SPDX | Holder |
|---|---|---|
| pnpm (`pnpm`) | **MIT** | Copyright (c) 2015-2016 Rico Sta. Cruz and other contributors; Copyright (c) 2016-2026 Zoltan Kochan and other contributors |

Verified at the Phase 1.5 license gate:

```
$ gh api repos/pnpm/pnpm/license --jq '.license.spdx_id'
MIT
```

Permissive; redistribution of the compiled artifact is granted provided the
copyright notice and permission notice are retained. The terms are those of
<https://github.com/pnpm/pnpm/blob/main/LICENSE>.

The published artifact is a Node.js single-executable-application: the `pnpm`
launcher plus the sibling `dist/` tree it loads at runtime. That tree bundles
third-party npm packages under their own permissive licenses, each shipping its
own `LICENSE` file inside `dist/node_modules/`, redistributed unmodified.

The pnpm name is used for catalog identification under nominative fair use.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
