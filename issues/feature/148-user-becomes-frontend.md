---
id: FEAT-148
type: feature
priority: high
status: open
---

# `user` becomes a frontend — dispatcher pattern + libexec lookup + `<user>`-context routing

## Description

**As a** maintainer
**I want** `bin/user` to expose its existing system-level
verbs (list / create / delete / add) AND act as a frontend
for user-scoped sub-services under `libexec/user/`, with the
existing `<user> <verb>` syntax routing the verb in that
user's context
**So that** mails (FEAT-149, was mailfilter), api (FEAT-150), and any
future user-scoped tool become reachable as `user
<sub-service> <verb>` (current user) and
`<user> <sub-service> <verb>` (act as that user).

## Implementation

### Verb tree

System-level (existing builtins, kept):

    user list
    user create <user>
    user delete <user>
    user add <user> <group>
    <user> exec                     # existing — read script from
                                     # stdin, run as that user

New: sub-service routing.

    user <sub-service> <verb>       # current user's context
    <user> <sub-service> <verb>     # that user's context, via
                                     # sudo -u <user> or equivalent

### Dispatcher

`bin/user`'s tail does the standard libexec lookup per
FEAT-001, with the additional `<user>`-prefix detection:

    # Detect "user-prefixed" form: first arg is a known system
    # user → context-switch
    if id "$1" >/dev/null 2>&1; then
        TARGET_USER=$1
        shift
        if has command $1; then
            sudo -u "$TARGET_USER" "$0" "$@"
        elif test -x "$LIBEXEC/user/$1"; then
            sudo -u "$TARGET_USER" "$LIBEXEC/user/$1" "${@:2}"
        fi
    elif has command $1; then
        command:$1 "${@:2}"
    elif test -x "$LIBEXEC/user/$1"; then
        exec "$LIBEXEC/user/$1" "${@:2}"
    fi

(Implementation detail; the principle is: first arg is a
user → switch context first, then dispatch the rest.)

### Sub-service contract

Each `libexec/user/<sub-service>` is a normal executable
script, run in the calling user's context. It shouldn't
care whether it was invoked directly (`user <sub-service>`)
or via the `<user>` prefix (`alice <sub-service>`) — the
`sudo -u` wrapper handles the context switch transparently.

### No new system-level verbs

The frontend doesn't add new system-level verbs in this
ticket. FEAT-149 (mails) and FEAT-150 (api) will
populate `libexec/user/`.

## Acceptance Criteria

1. `user help` lists the existing system-level verbs.
2. After FEAT-149 lands, `user mails list` runs
   `libexec/user/mails list` in the current user's
   context.
3. `alice mails list` switches to alice's context (via
   `sudo -u alice` or the platform equivalent) before
   running the sub-service.
4. The existing `<user> exec` continues to work unchanged.
5. The dispatcher's `<user>`-detection uses `id "$1"
   >/dev/null`; non-existing-user first args fall through
   to the standard error path.
