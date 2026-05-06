---
id: FEAT-184
type: feature
priority: medium
status: open
---

# `user shell` sub-service: dotfiles + helpers + startup.d as a curated installer

## Description

**As a** user installing the `user` package on a fresh
machine
**I want** a `user shell` sub-service that sets up my bash
environment — the dotfiles (`bashrc`, `bash_profile`,
`profile`, `bash_logout`, `inputrc`), the sourced helpers
(`colors`, `exports`, `icons`, `pear`, `prompt`), and the
~85-helper startup.d library — symlinked into the right
places idempotently
**So that** "set up a sane bash environment" is one command
(`user shell setup`) and the `user` package automatically
calls it on install via the rpk post-install hook.

This absorbs `etc/{bashrc,bash_profile,profile,bash_logout,
inputrc}`, `etc/bash/{colors,exports,icons,pear,prompt}`,
and `etc/bash/startup.d/*` from this repo — they become the
shipped content of the `user` package after extraction.

The bashrc + bash_profile already expect this layout (they
load helpers from `~/.local/etc/bash/...` and from
`/usr/local/etc/bash/...`); the installer just makes the
files exist.

## Implementation

### Subcommands (under `user shell`)

    user shell setup [--system | --user]
                                # default: --user; --system requires sudo
    user shell uninstall
    user shell reload           # `exec bash` after a config change
    user shell list             # show installed helpers + startup.d
    user shell show <helper>    # cat a startup.d helper

    user shell host add <host>
    user shell host edit <host> # $EDITOR on hosts.d/<host>/<file>
    user shell host remove <host>
    user shell host list

### Install layout

Per-user mode:

    ~/.bashrc                              → symlink → pkg's bashrc
    ~/.bash_profile                        → symlink → pkg's bash_profile
    ~/.profile                             → symlink → pkg's profile
    ~/.bash_logout                         → symlink → pkg's bash_logout
    ~/.inputrc                             → symlink → pkg's inputrc
    ~/.local/etc/bash/colors               → symlink
    ~/.local/etc/bash/exports              → symlink
    ~/.local/etc/bash/icons                → symlink
    ~/.local/etc/bash/pear                 → symlink
    ~/.local/etc/bash/prompt               → symlink
    ~/.local/etc/bash/startup.d/*          → symlinks (curation policy
                                              below)
    ~/.local/etc/bash/hosts.d/<host>/      → user-managed (never
                                              overwritten)

System mode targets `/etc/...` and `/usr/local/etc/bash/...`
(parallel paths the bashrc already knows about).

### Preserve user content

`~/.bash_aliases` and `~/.bash_functions` are **never
touched** by the installer; bashrc sources them if they
exist. The installer also leaves the contents of
`~/.local/etc/bash/hosts.d/<host>/` alone.

If a target path exists and is a real file (not a symlink
to the package's version), `setup` backs it up to
`<path>.before-user-shell` and proceeds — the user can
restore manually.

### Curation policy for startup.d

Default `setup` installs an **essential set** (~20 helpers:
`alert`, `calc`, `extract`, `fcd`, `ff`, `genpw`, `grep`,
`gz`, `history`, `json`, `ls`, `mkd`, `note`, `pager`,
`replace`, `sshknownhosts`, `t`, `tre`, `umask`, `wget`).

Full library (all 85) opt-in via `setup --select all` or
hand-pick via `setup --select alert,calc,history,...`.

`user shell list` shows installed + available.

### rpk install hook

The `nostra124/user` package's post-install script (per
FEAT-152's `.rpk/release` or equivalent) **calls `user
shell setup` automatically** for the installing user
(detected via `SUDO_USER` if running under sudo, otherwise
the current `$USER`). Non-interactive — uses default
options.

A `--no-shell-setup` flag on `rpk install user` (or an env
var `USER_SKIP_SHELL_SETUP=1`) opts out for users who want
manual control.

Composes with `check` (FEAT-110): a packaged check file
verifies the symlinks exist and resolve.

## Acceptance Criteria

1. `user shell setup` on a fresh machine creates the
   symlinks listed above; re-running is idempotent (no
   duplicates, no errors).
2. Pre-existing real files at the target paths are backed
   up to `<path>.before-user-shell`; the symlink is then
   created.
3. `~/.bash_aliases` / `~/.bash_functions` are never
   touched.
4. `user shell uninstall` removes only the symlinks the
   installer created; user-managed files survive.
5. `user shell host add foo` creates
   `~/.local/etc/bash/hosts.d/foo/` and seeds an
   `editme.sh`; the existing `bashrc` sources files there
   on hosts named `foo`.
6. The default startup.d set installs ~20 helpers; `setup
   --select all` installs all 85.
7. `rpk install user` post-install hook runs `user shell
   setup` for the installing user; `--no-shell-setup` or
   `USER_SKIP_SHELL_SETUP=1` skips it.
8. Tests / SIT cover idempotency, the backup behaviour,
   and the post-install-hook integration.
