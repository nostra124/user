---
name: user-user
description: |
  Operate the `user` system-user manager and per-user
  sub-service frontend — create/delete/add system users,
  run sub-services (git, srv, mails, api, shell) per
  user, install dotfiles/shell config. Trigger when the
  user wants to add a system user, run a script as
  another user, or set up shell/dotfiles.
---

# `user-user` skill

## 1. Design principles

- **Educational.** Reading `bin/user` end-to-end
  teaches the canned-account pattern (each system
  user has a home convention + group + ssh setup).
- **Functional.** Each verb is a sequence of system
  primitives (adduser, dseditgroup, mkdir, sudo).
- **Decentralized.** Per-user sub-services; no
  central agent.
- **Simple.** `user` calls only `account` at runtime
  (for `account init <user>@localhost`).

## 2. The model

`user` has two modes:

**System-level (existing builtins):**

    user list
    user create <name>           # /var/lib/<name>, group `users`
    user delete <name>
    user add <name> <group>
    <name> exec                  # script from stdin

**Sub-service routing (FEAT-148, in progress):**

    user <sub-service> <verb>     # runs as current user
    <user> <sub-service> <verb>   # runs as <user> via sudo

Sub-services planned:

| Sub-service | Source                     | Status              |
|-------------|----------------------------|---------------------|
| git         | libexec/user/git           | done (FEAT-167)     |
| srv         | libexec/user/srv           | done (FEAT-167)     |
| mails       | bin/mailfilter             | filed (FEAT-149)    |
| api         | bin/api + provider/task    | filed (FEAT-150)    |
| shell       | dotfiles + startup.d       | filed (FEAT-184)    |

## 3. Workflow recipes

1. **List system users.**

       user list

2. **Create the canned `srv` user.**

       user create srv     # /srv home, subuid/subgid set up

3. **Run a script as another user.**

       user alice exec <<'EOF'
       echo "hi from $(whoami) at $(date)"
       EOF

4. **Set up the git-hosting user (canned).**

       user create git
       user git setup    # FEAT-167's libexec/user/git

5. **Install your shell config (FEAT-184 pending).**

       user shell setup

6. **Top-level user-environment bootstrap (FEAT-185
   pending).**

       user setup

## 4. Guardrails

1. **`user create srv` does subuid/subgid magic** for
   container compatibility — only run on a host that
   actually wants podman/docker rootless support.
2. **`user delete <name>` removes /var/lib/<name>.**
   No undo; back up first.
3. **`user <name> exec` runs a script via
   `sudo -u`** — the script inherits root's PATH and
   env, not yours. Quote and qualify.
4. **Sub-service routing depends on
   `libexec/user/<sub>` existing.** mails/api/shell
   are filed but not yet implemented (FEAT-149/150/
   184).
5. **`user create <name>` calls
   `account init <name>@localhost`** under the hood.
   That generates GPG/SSH keys for the new user;
   verify there's keyspace before mass-creating.

## 5. Where to read more

- `man user`
- `man account` — the identity foundation user is
  built on
- This package's `CLAUDE.md`
