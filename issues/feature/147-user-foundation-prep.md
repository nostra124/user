---
id: FEAT-147
type: feature
priority: high
status: open
---

# User foundation prep — call only `account` and `config` at runtime

## Description

**As a** maintainer preparing to extract `user` as its own
rpk package (the frontend for user-scoped tools)
**I want** `bin/user`'s call set cleaned up to the standard
foundation contract
**So that** the package ships as a clean foundation that
mailfilter (FEAT-149) and api (FEAT-150) build on as
sub-services.

Today `bin/user` (285 lines, 7 verbs) calls account, cache,
config, repo per the dep map. After cleanup: only `account`
+ `config` at runtime.

Cycles to break: `user ↔ repo` was already addressed by
FEAT-104 (repo dropping the user dep). This ticket addresses
user's outbound — the inverse — confirming `user → repo` is
gone too (per the established direction "everything → account
/ config; nothing → user").

## Implementation

1. **Audit** `bin/user`'s outbound script calls:

       grep -wEn '(cache|check|data|hosts|repo|scripts|secret|task|api|mailfilter)' bin/user

2. **Resolve**:
   - `account` — kept (`user → account`).
   - `config` — kept (`user → config`).
   - `cache` — verify-grep should return clean (cache was
     removed entirely by FEAT-045).
   - `repo` — remove. Use git directly if user's existing
     code touched repos.
   - `data`, `scripts`, `secret`, `task` — remove if present
     (verify-grep should return clean).
   - `mailfilter`, `api` — these are about to become *sub-
     services* under user (FEAT-149/150); not external script
     calls.

3. **Add `docs/templates/CLAUDE.md.user`** derived from the
   foundation template. Sections: scope (system user mgmt +
   frontend for user-scoped tools), the dispatcher pattern
   (builtin verbs + libexec sub-services), no-shared-lib
   policy, intentional duplications.

## Acceptance Criteria

1. `grep -wEn '(cache|check|data|hosts|repo|scripts|secret|task|api|mailfilter)' bin/user`
   returns no script-invocation matches.
2. `bin/user help` lists the same builtin verbs as before
   (sub-services land in FEAT-148..150).
3. `docs/templates/CLAUDE.md.user` exists.
4. Existing user smoke tests (or a minimal suite added here)
   pass after the refactor.
