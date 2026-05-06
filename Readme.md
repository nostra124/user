# `user`

> System-user management with per-user sub-services: api / mails / git / srv

## Install

    git clone https://github.com/nostra124/user
    cd user
    ./install --prefix=$HOME/.local

Or in two steps:

    ./configure --prefix=$HOME/.local
    make install

## Quick start

    user help
    user version

## Layout

| Path | Purpose |
|---|---|
| `bin/user` | the entry point |
| `libexec/user/` | sub-commands (where applicable) |
| `docs/user.md` | CLI contract reference |
| `share/man/man1/user.1` | man page |
| `share/doc/user/standards/` | vendored references (educational) |
| `skills/user-user/` | agent skill |
| `tests/unit/user.bats` | unit tests |
| `tests/sit/` | system integration (when present) |
| `.cpk/` | container packaging overlay |
| `.rpk/` | rpk metadata (version, versions ledger, depends/) |

## Documentation

- `man user`
- `docs/user.md` — CLI contract reference
- `share/doc/user/standards/README.md` — vendored standards
- `CLAUDE.md` — agent guide
- `skills/user-user/SKILL.md` — agent skill

## Conventions

This package follows the rpk per-script repo convention:

- Per-script repo: this repo contains only `user`'s artefacts.
- No shared library: helper boilerplate is duplicated, not factored out (see `CLAUDE.md` §4–5).
- Stow-based install via `make install`.
- Versioning: semver, with `.rpk/version` as the source of truth and `.rpk/versions` as the per-release SHA ledger.

## License

GPL-3 (per the cross-cutting policy in the parent `scripts` collection).
