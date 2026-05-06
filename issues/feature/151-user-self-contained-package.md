---
id: FEAT-151
type: feature
priority: high
status: open
---

# User self-contained packaging: docs, tests, man, completion, CLAUDE.md

## Description

**As a** maintainer about to extract `user` to its own rpk
repo
**I want** the standard packaging artefacts in place — docs,
tests, man page, completion, `CLAUDE.md`
**So that** the extraction (FEAT-152) is mechanical.

Mirrors FEAT-105 (repo) / FEAT-108 (event) / FEAT-093
(services, packaging-only). Operational, not pedagogical —
no STANDARDS section, no vendored docs, no agent skill.

## Implementation

Depends on FEAT-147 (foundation prep), FEAT-148 (frontend
dispatcher), FEAT-149 (mails sub-service), FEAT-150
(api sub-service).

For `bin/user`:

1. **`docs/user.md`** per FEAT-004: synopsis, description
   (system user mgmt + the frontend pattern), every
   subcommand including the sub-services with their full
   verb sets, environment, files
   (`/var/lib/<user>` home dirs; per-sub-service config
   under user's config home), exit codes, cross-script
   dependencies (after FEAT-147: `account` + `config` at
   runtime; soft `procmail` for mails, `curl` for api).

2. **`tests/unit/user.bats`** per FEAT-003: covers the
   builtin system-user verbs; `tests/unit/user-mails.bats`
   and `tests/unit/user-api.bats` cover the sub-services.
   Tests sandbox `$HOME` and mock `id` / `sudo` for the
   `<user>`-context routing.

3. **`share/man/man1/user.1`** (groff). Sections: NAME,
   SYNOPSIS, DESCRIPTION (the frontend pattern: builtins +
   sub-services + `<user>`-context routing), SUBCOMMANDS
   (system-level), **SUB-SERVICES** (one subsection per
   `libexec/user/<name>` — mails, api), ENVIRONMENT,
   FILES, EXIT STATUS, EXAMPLES, **MIGRATION** (note that
   `mails` (formerly `bin/mailfilter`) and `api` were standalone scripts in v1
   and now live under `user`), SEE ALSO.

4. **`etc/bash_completion.d/user`** — context-aware:
   `user <TAB>` (builtins + sub-services + known users),
   `user <user> <TAB>` (sub-services for context-routed
   form), `user <sub-service> <TAB>` (sub-service verbs).

5. **`docs/templates/CLAUDE.md.user`** — already drafted in
   FEAT-147; finalise here. Calls out the frontend pattern
   so future sub-services follow the convention.

## Acceptance Criteria

1. `bin/user`'s dispatcher is small; sub-service logic lives
   under `libexec/user/`.
2. `docs/user.md` covers every subcommand (system-level +
   sub-services).
3. `bats tests/unit/user.bats tests/unit/user-mails.bats
   tests/unit/user-api.bats` passes.
4. `man -l share/man/man1/user.1` renders all sections; the
   SUB-SERVICES section documents mails + api with
   full verb sets.
5. Tab completion works at the three levels (top, user-prefix,
   sub-service).
6. `docs/templates/CLAUDE.md.user` is finalised with the
   frontend convention documented.
