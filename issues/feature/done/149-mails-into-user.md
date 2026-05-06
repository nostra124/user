---
id: FEAT-149
type: feature
priority: medium
status: done
---

# Move `bin/mailfilter` → `libexec/user/mails`

## Description

**As a** maintainer
**I want** `mailfilter` absorbed into the `user` package as
a sub-service, accessible as `user mails <verb>`
**So that** the procmail-based mail filtering lives where
it conceptually belongs (a per-user concern), and there's
no separate top-level `bin/mailfilter` to maintain.

Today `bin/mailfilter` (292 lines, 12 verbs — list / maildir
/ logfile / monitor / folders / senders / whitelist / from /
learn / apply) is its own top-level. After this ticket: it
lives at `libexec/user/mails`, reachable via the user
frontend's libexec dispatch (FEAT-148).

## Implementation

1. **Move** `bin/mailfilter` to `libexec/user/mails`.
   Adjust internal references (e.g. `$0`-based path
   resolution).

2. **Audit** outbound script calls and clean per the
   foundation rules:

       grep -wEn '(cache|check|data|hosts|repo|scripts|secret|task)' libexec/user/mails

   Resolve: `account` kept; `config` kept (read its own
   config files); others removed.

3. **Verb surface unchanged.** `user mails list /
   maildir / logfile / monitor / folders / senders / whitelist
   / from / learn / apply` reach the same code paths the old
   `mailfilter list / …` did.

4. **Soft system deps**: `procmail` (and the mail tooling it
   needs — `formail`, etc.); probed at runtime per the
   FEAT-039 pattern.

5. **`bin/mailfilter` is deleted** in this same commit.

6. **Migration note** in the commit message and in the
   user(1) man page (FEAT-151): `mailfilter <verb>` →
   `user mails <verb>`.

### Modernization (deferred)

procmail is dated; `sieve` (RFC 5228, IMAP-standard) is the
modern alternative. A future ticket can add a sieve backend
alongside procmail and let the user pick. Out of scope for
this ticket.

## Acceptance Criteria

1. `bin/mailfilter` no longer exists; `libexec/user/mails`
   does.
2. `user mails <verb>` for every previous verb works
   end-to-end (in the current user's context).
3. `alice mails list` works via the `<user>`-context
   routing from FEAT-148 (runs as alice).
4. `grep -wEn '(cache|check|data|hosts|repo|scripts|secret|task)' libexec/user/mails`
   returns no script-invocation matches.
5. `procmail` is soft-probed; missing tooling fails clearly
   on `apply` / `learn` etc. without breaking unrelated
   mailfilter verbs.

## Resolution

Closed by the user-absorption PR.

- bin/mailfilter → user/libexec/user/mails (move + rename).
- user dispatcher gains command:mails → exec libexec/user/mails.
- Verb surface unchanged: `user mails <verb>` reaches the same code
  paths bin/mailfilter did.
- No bats migration (mailfilter never had a tests/unit/mailfilter.bats);
  follow-up bats lands as a v0.19.5.x ticket.
- **Divergence**: outbound script-call audit (acceptance #2) is
  out of scope for this PR; the file moved verbatim. Foundation-rule
  cleanup is a v0.19.5.x follow-up.
