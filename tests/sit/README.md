# `tests/sit/` — System integration tests

Exercises `.rpk/depends/*` end-to-end against real OS package
managers, in clean containers.

## Running

    tests/sit/run.sh                  # default matrix (see below)
    tests/sit/run.sh debian:stable    # one image
    tests/sit/run.sh img1 img2 …      # explicit list

Default engine is `podman`; override with `SIT_ENGINE=docker`.

## Default matrix

| Image                | Package manager |
|----------------------|-----------------|
| `debian:stable-slim` | `apt-get`       |
| `ubuntu:24.04`       | `apt-get`       |
| `fedora:latest`      | `dnf`           |
| `archlinux:latest`   | `pacman`        |
| `alpine:latest`      | `apk`           |

macOS / Homebrew is not exercised here — `tests/sit/in-container.sh`
runs with the package-manager-of-the-host, so on Darwin the brew
branch is reachable only when the script is run directly outside a
container.

## What it covers

`tests/sit/in-container.sh` runs three blocks:

1. **System-tool deps** (`depends/git`, `depends/stow`):
   removes the package via the host's package manager, runs the
   depends script, asserts the binary is on `PATH` afterwards.
   `depends/bash` is only checked for the no-op short-circuit
   because `/bin/sh` may itself be bash.

2. **`depends/rpk`**: asserts the script *errors* when
   `$HOME/.local/bin/rpk` is missing and *succeeds* when it
   exists. No install is attempted (rpk doesn't install rpk).

3. **`depends/account`**: stubs `$HOME/.local/bin/rpk` to record
   its arguments and asserts that on a cold cache the script
   issues `rpk import …/account` followed by `rpk install
   account`, and on a warm cache (`rpk list` returns `account`)
   it skips the import and only runs `rpk install account`.

## Wiring

The Makefile's `check-sit` target calls this runner. Run from
the repo root:

    make check-sit
