#!/usr/bin/env bats
#
# Unit tests for bin/user — the os-agnostic system-user manager
# (FEAT-147..152). Pinned to semver per FEAT-005.
#
# Coverage scope: every subcommand whose happy path doesn't require
# sudo/adduser/sysadminctl. `create`, `delete`, `add`, `exec` and
# the `<user> exec` indirection all need a real privileged shell
# and real users — they belong to the SIT suite that lands per
# the user-package self-contained-package ticket.

setup() {
	BATS_TMPDIR=${BATS_TMPDIR:-$(mktemp -d)}
	HOME="$(mktemp -d "$BATS_TMPDIR/home.XXXXXX")"
	unset XDG_CACHE_HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_SHARE_HOME
	unset XDG_SOURCE_HOME XDG_BACKUP_HOME XDG_RUNTIME_DIR
	export HOME
	export SELF_QUIET=1
	export USER_BIN="$BATS_TEST_DIRNAME/../../bin/user"
}

teardown() {
	rm -rf "$HOME"
}

# ---------------------------------------------------------------------------
# Smoke + semver contract (FEAT-005)
# ---------------------------------------------------------------------------

@test "user binary exists and is executable" {
	[ -x "$USER_BIN" ]
}

@test "user version returns 1.0.0" {
	run "$USER_BIN" version
	[ "$status" -eq 0 ]
	[ "$output" = "1.0.0" ]
}

@test "user help prints usage" {
	run "$USER_BIN" help
	[ -n "$output" ]
}

@test "user with no args prints help" {
	run "$USER_BIN"
	[ -n "$output" ]
}

@test "user unknown subcommand exits non-zero (BUG-005 regression)" {
	run "$USER_BIN" definitely-not-a-real-subcommand
	[ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Help surface — every documented subcommand should be discoverable
# ---------------------------------------------------------------------------

@test "help mentions list / create / delete subcommands" {
	run "$USER_BIN" help
	[[ "$output" == *"list"* ]]
	[[ "$output" == *"create"* ]]
	[[ "$output" == *"delete"* ]]
}

@test "help mentions add (group membership) subcommand" {
	run "$USER_BIN" help
	[[ "$output" == *"add"* ]]
}

@test "help mentions <user> exec indirection" {
	run "$USER_BIN" help
	[[ "$output" == *"exec"* ]]
}

# ---------------------------------------------------------------------------
# Early-validation error paths — flow through the BUG-005-fixed
# fatal helper.
# ---------------------------------------------------------------------------

@test "create without user name exits non-zero" {
	run "$USER_BIN" create
	[ "$status" -ne 0 ]
	[[ "$output" == *"Please specify a user name"* ]]
}

@test "delete without user name exits non-zero" {
	run "$USER_BIN" delete
	[ "$status" -ne 0 ]
	[[ "$output" == *"Please specify a user name"* ]]
}

@test "add without user name exits non-zero" {
	run "$USER_BIN" add
	[ "$status" -ne 0 ]
	[[ "$output" == *"Please specify a user name"* ]]
}

@test "add with user but no group exits non-zero" {
	run "$USER_BIN" add alice
	[ "$status" -ne 0 ]
	[[ "$output" == *"Please specify a group name"* ]]
}

@test "exec without user name exits non-zero" {
	run "$USER_BIN" exec
	[ "$status" -ne 0 ]
	[[ "$output" == *"Please specify a user name"* ]]
}
