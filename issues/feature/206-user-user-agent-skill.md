---
id: FEAT-206
type: feature
priority: low
status: open
---

# `user-user` agent skill

## Description

**As a** user delegating system-user + shell-environment
+ mail / api setup tasks to an AI agent
**I want** a packaged skill that teaches the agent the
user umbrella — system user mgmt, the `<user>`-context
routing, mails (was mailfilter) and api sub-services,
the `user shell` environment installer, the top-level
`user setup` bootstrap
**So that** an agent can bootstrap a fresh user account
end-to-end correctly.

## Implementation

Layout:

    skills/
    └── user-user/
        ├── SKILL.md
        └── opencode.md

`SKILL.md` frontmatter:

    ---
    name: user-user
    description: Operate the `user` umbrella — manage
      system users (list / create / delete / add to
      group), run sub-services in a user's context
      (mails / api), install the curated bash
      environment via `user shell setup`, bootstrap a
      fresh user account end-to-end via `user setup`.
      Trigger when the user wants to create a new system
      user, set up shell environment, configure mail
      filters or api credentials, or run a command as
      another user.
    ---

Body sections per FEAT-192:

1. Design principles.
2. **Model**: frontend pattern. Builtin verbs (list /
   create / delete / add) for system-user mgmt. Sub-
   services under `libexec/user/` (mails per FEAT-149,
   api per FEAT-150, shell per FEAT-184, git/srv per
   FEAT-167). `<user> <verb>` syntax routes via
   `sudo -u <user>` for context switching. `user setup`
   composes create + ssh + shell-setup + base-rpk-install
   (FEAT-185).
3. Workflow recipes:
   - bootstrap a fresh user end-to-end
     (`user setup alice`)
   - just shell setup for the current user
     (`user shell setup`)
   - mail-filter rules (`user mails …`)
   - api access via providers / tasks
     (`user api …`)
   - run a command as another user
     (`<user> exec` or `<user> <sub-service>`)
   - per-host shell customisation via
     `user shell host add <host>`
4. Guardrails:
   - **Don't delete a system user without `--purge`
     confirmation** — irreversible (#1).
   - `user shell setup` preserves user-managed
     `~/.bash_aliases` and `~/.bash_functions`; never
     overwrite them.
   - Pre-existing real files at symlink targets are
     backed up to `<path>.before-user-shell` — review
     before assuming overwrite is safe.
   - `<user>`-context routing requires `sudo` (or
     platform equivalent); on macOS check `dscl` /
     launchd integration first.
   - The `nostra124/user` rpk post-install hook calls
     `user shell setup` automatically; opt out via
     `--no-shell-setup` or `USER_SKIP_SHELL_SETUP=1`.
5. Where to read more: `man user`, walkthrough,
   `docs/templates/CLAUDE.md.user`.

Installation per the established pattern.

## Acceptance Criteria

1. `skills/user-user/SKILL.md` and `opencode.md` exist.
2. `make install` + `make install-skills-user` work.
3. Guardrail "don't delete a system user without
   --purge" called out as #1.
4. The `<user>`-context routing pattern is explicit.
5. The post-install-hook auto-call of `user shell setup`
   is documented.
