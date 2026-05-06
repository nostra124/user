---
id: FEAT-185
type: feature
priority: low
status: open
---

# `user setup` — top-level user-environment bootstrap

## Description

**As a** machine operator setting up a new system user
**I want** `user setup [<user>]` to be the one command that
bootstraps a fresh user account end-to-end — create the
system user, set up SSH access, run `user shell setup` for
that user, and optionally install a baseline set of rpk
packages
**So that** "make a usable user account on this machine" is
one verb instead of three.

Composes the existing `user create / add` (system-level)
with the new `user shell setup` (FEAT-184) and an optional
rpk install pass.

## Implementation

### Verb

    user setup <name>                            # create + ssh + shell
                                                  # + base-rpk
    user setup <name> --no-shell                 # skip shell-env step
    user setup <name> --no-base                  # skip rpk-install step
    user setup <name> --add <pkg> [--add <pkg>]  # extra rpk packages
    user setup <name> --exclude <pkg>            # drop from base list

### Steps

1. `user create <name>` — system user + home dir.
2. SSH access from the invoking account (the existing
   create flow already does this).
3. `<name> shell setup --user` — runs in the new user's
   context (per FEAT-148's `<user>`-prefix routing) and
   sets up that user's bash environment.
4. If `--no-base` not set, install the **base rpk package
   set** as that user. Default list mirrors cpk's base
   layer (FEAT-133):

       account / config / secret / crypt / repo / event /
       services / check / cluster / dht / bitcoin / user /
       project

   Override via `--add` / `--exclude`.
5. Print a summary of what was done.

### Idempotency

Re-running `user setup <name>` is a no-op for steps that
already completed (each step's verb is idempotent). Use
case: re-run after upgrading to pick up new base-package
defaults.

### Security note

`user setup` runs as the invoking user (likely root or via
sudo) for create / ssh / rpk-install steps; the shell-setup
sub-step runs in the new user's context via `sudo -u <name>`.
The flow doesn't leak the invoker's shell environment into
the new user.

## Acceptance Criteria

1. `user setup alice` on a fresh machine creates the alice
   system user, sets up ssh access, runs alice's shell
   setup, and installs the default base rpk package set
   for alice.
2. Re-running `user setup alice` is a no-op (every sub-step
   detects already-done state).
3. `--no-base` skips the rpk install pass.
4. `--add infra --exclude bitcoin` adjusts the package list.
5. Failure of any sub-step prints a clear diagnostic and
   stops; partial-progress can be resumed by re-running.
6. SIT covers a fresh-container "create alice from scratch"
   end-to-end + a "re-run is no-op" verification.
