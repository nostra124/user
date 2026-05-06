---
id: FEAT-167
type: feature
priority: low
status: open
---

# Move `etc/scripts/usr/{git,srv}` → `libexec/user/{git,srv}`

## Description

**As a** maintainer
**I want** the canned user-account setup scripts under
`etc/scripts/usr/` (`git` and `srv`) absorbed into the
`user` package as libexec sub-services
**So that** they live alongside `mailfilter` (now `mails`,
per FEAT-149) and `api` (per FEAT-150) and become reachable
as `user git <args>` / `user srv <args>`.

The `git` and `srv` scripts set up the corresponding
system users with predefined config (git-hosting user;
service-hosting user). They're conceptually canned versions
of `user create` for those particular roles.

## Implementation

1. **Move** `etc/scripts/usr/git` → `libexec/user/git`.
2. **Move** `etc/scripts/usr/srv` → `libexec/user/srv`.
3. **Delete** the now-empty `etc/scripts/usr/` directory.
4. **Verify** with the user package's libexec dispatch
   (FEAT-148) that `user git ...` and `user srv ...` reach
   the new locations.
5. **Audit** outbound script calls per the foundation
   rules; only `account` and `config` should remain.
6. **Document** in the user(1) man page (FEAT-151) under
   the SUB-SERVICES section: `git` and `srv` alongside
   `mails` and `api`.

## Acceptance Criteria

1. `etc/scripts/usr/` no longer exists.
2. `libexec/user/git` and `libexec/user/srv` exist as
   executable sub-services.
3. `user git <args>` and `user srv <args>` reach the new
   sub-services via the FEAT-148 dispatcher; `<user> git
   <args>` runs in the named user's context.
4. The user(1) man page (FEAT-151) lists `git` and `srv`
   under SUB-SERVICES.
5. Existing smoke tests for the user package pass after
   the addition.
