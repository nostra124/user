# `user` — developer notes

> Mirrors `CLAUDE.md.foundation`, specialised for `user`.

## 1. Scope

`user` manages system users and acts as a frontend for
per-user sub-services (git, srv, mails, api, shell).

Out of scope: identity primitives (that's `account`);
secrets (that's `secret`); per-project config (that's
`project`).

## 2. Repo conventions

Standard rpk per-package: `bin/user` dispatcher with
`command:<verb>` builtins for system-level verbs plus
a libexec lookup for sub-services (FEAT-148, partly
implemented).

## 3. Issue authoring

Same as `CLAUDE.md.foundation`. **Bugs come before
features at the same priority level.**

## 4. The no-shared-lib policy

`user` calls only `account` at runtime (for
`account init <user>@localhost` during user creation).

Sub-services under `libexec/user/<sub>/` are
self-contained — they don't share helpers with the
top-level dispatcher.

## 5. What is intentionally duplicated

- **Per-platform user-creation idioms** (`adduser`
  on Linux vs `sysadminctl` on macOS). Inline in
  `command:create`; never via a shared
  platform-helper module.
- **subuid/subgid setup** (for the canned `srv`
  user). Inline.

## 6. Consumers

End users; container image builds (the cpk-base may
call `user create srv`); cluster node init
(`account init` triggers `user create`).

## 7. Build / install

`./configure && make install`. Stow-based.

## 8. Versioning

Semver. `tests/unit/user.bats` is the contract.
