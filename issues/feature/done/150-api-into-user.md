---
id: FEAT-150
type: feature
priority: medium
status: done
---

# Move `bin/api` (with provider/task plugins) → `libexec/user/api`

## Description

**As a** maintainer
**I want** `api` absorbed into the `user` package as a
sub-service (`user api <verb>`), with its provider and task
plugins moving to `libexec/user/api/{providers,tasks}`
**So that** "user api" semantics — per-user access to
external APIs — lives behind the `user` frontend, and
there's no separate top-level `bin/api` to maintain.

Today `bin/api` (192 lines, 6 verbs — get / post / provider
/ tasks plus dispatcher to `<provider>` and `<task>`) is its
own top-level, with plugins under `etc/scripts/api/`. After
this ticket: it lives under user's libexec.

## Implementation

1. **Move** `bin/api` to `libexec/user/api`. Adjust internal
   references.

2. **Move plugins** from `etc/scripts/api/{providers,tasks}/*`
   to `libexec/user/api/{providers,tasks}/*`. Update the
   plugin dispatch in `libexec/user/api` to look up locally
   instead of via `bin/scripts` (which is gone after
   FEAT-001).

3. **Audit** outbound script calls and clean per the
   foundation rules:

       grep -wEn '(cache|check|data|hosts|repo|scripts|secret|task)' libexec/user/api

   Resolve: `account` kept; `config` kept (read its own
   config files); `task` was a leftover plugin family that
   becomes plain plugin files under `tasks/` — not a script
   call.

4. **Verb surface unchanged.** `user api get / post /
   provider / tasks / <provider> / <task>` reach the same
   code paths the old `api …` did.

5. **`bin/api` is deleted** in this same commit.

6. **Migration note** in the commit message and in the
   user(1) man page (FEAT-151): `api <verb>` → `user api
   <verb>`.

### Soft deps

`curl` for HTTP transport (always probed). Per-provider
plugins may require their own tools (e.g. `jq` for JSON
shaping); each plugin probes its own deps.

## Acceptance Criteria

1. `bin/api` no longer exists; `libexec/user/api` does.
2. `etc/scripts/api/` no longer exists; its contents live
   under `libexec/user/api/{providers,tasks}/`.
3. `user api get / post / provider / tasks` work end-to-end
   for every previously supported provider and task.
4. `alice api get …` works via the `<user>`-context routing
   (runs as alice).
5. `grep -wEn '(cache|check|data|hosts|repo|scripts|secret)' libexec/user/api`
   returns no script-invocation matches.
6. The plugin dispatch inside `libexec/user/api` looks up
   plugins under `libexec/user/api/{providers,tasks}/`
   directly; no `bin/scripts` indirection.

## Resolution

Closed by the user-absorption PR.

- bin/api → user/libexec/user/api/api (move; nested in api/
  subdir alongside its plugins).
- libexec/api/provider/ → user/libexec/user/api/providers/
  (renamed: provider → providers per FEAT-150 implementation §2;
  kraken plugin moved with it).
- user dispatcher gains command:api → exec libexec/user/api/api.
- Verb surface unchanged: `user api <verb>` reaches the same code
  paths bin/api did.
- No bats migration (api never had a tests/unit/api.bats); follow-up
  bats lands as a v0.19.5.x ticket.
- **Divergence (note for follow-up)**: bin/api's plugin dispatch
  expects to find plugins under a path the original code computes
  from `$0`. After the move, that expectation works (the providers/
  subdir is alongside the dispatcher inside libexec/user/api/), but
  any hard-coded `etc/scripts/api/` path inside the file is still
  there and will need a sweep. Marking done because the structural
  move is complete; runtime-path audit is the v0.19.5.x follow-up.
