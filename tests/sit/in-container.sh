#!/bin/sh
# tests/sit/in-container.sh — runs INSIDE a per-OS container, exercising
# .rpk/depends/* against that OS's real package manager and a stubbed rpk.
#
# Repo is bind-mounted at /work; we may not write to it. All scratch
# state lives under $TMP.
#
# Coverage:
#   - depends/bash, depends/git, depends/stow: real apt/dnf/yum/pacman/apk
#     install on the host distro (or brew on Darwin if invoked there
#     directly without a container).
#   - depends/rpk: errors when $HOME/.local/bin/rpk is missing; succeeds
#     when present.
#   - depends/account: invokes a stubbed rpk with `import` then `install`
#     on first run, only `install` on the second.

set -eu

DEPENDS=/work/.rpk/depends
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

HOME="$TMP/home"
mkdir -p "$HOME/.local/bin"
export HOME

PASS=0
FAIL=0

ok()    { PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"; }
fail()  { FAIL=$((FAIL + 1)); printf '  FAIL %s\n' "$1"; }
banner(){ printf '\n--- %s ---\n' "$1"; }

# -----------------------------------------------------------------------
# 1. system-tool deps: real install, asserts the binary appears
# -----------------------------------------------------------------------

banner "system-tool deps (real install)"

# Probe to pick a uninstall verb for the host PM, so we can force a
# missing-state before invoking the depends script.
remove_pkg() {
	pkg="$1"
	if command -v apt-get >/dev/null 2>&1; then
		apt-get remove -y "$pkg" >/dev/null 2>&1 || true
	elif command -v dnf >/dev/null 2>&1; then
		dnf remove -y "$pkg" >/dev/null 2>&1 || true
	elif command -v yum >/dev/null 2>&1; then
		yum remove -y "$pkg" >/dev/null 2>&1 || true
	elif command -v pacman >/dev/null 2>&1; then
		pacman -Rns --noconfirm "$pkg" >/dev/null 2>&1 || true
	elif command -v apk >/dev/null 2>&1; then
		apk del "$pkg" >/dev/null 2>&1 || true
	fi
}

# `apt-get update` is needed once for Debian/Ubuntu; harmless elsewhere
if command -v apt-get >/dev/null 2>&1; then
	apt-get update >/dev/null 2>&1 || true
fi

# git and stow: safe to remove (we don't shell-out to them in the
# dep script itself). Skip bash because /bin/sh on Alpine is busybox
# and removing bash mid-test could destabilise the runtime.
for tool in git stow; do
	remove_pkg "$tool"
	if command -v "$tool" >/dev/null 2>&1; then
		fail "$tool: still present after remove (cannot test install path)"
		continue
	fi
	if "$DEPENDS/$tool" >/dev/null 2>&1 && command -v "$tool" >/dev/null 2>&1; then
		ok "depends/$tool installed $tool on $(uname -s)"
	else
		fail "depends/$tool failed to install $tool"
	fi
done

# bash: only assert the no-op short-circuit (since /bin/sh might BE bash).
if "$DEPENDS/bash" >/dev/null 2>&1; then
	ok "depends/bash is a no-op when bash is present"
else
	fail "depends/bash unexpectedly errored when bash is present"
fi

# -----------------------------------------------------------------------
# 2. depends/rpk: presence assertion only
# -----------------------------------------------------------------------

banner "depends/rpk"

rm -f "$HOME/.local/bin/rpk"
if "$DEPENDS/rpk" >/dev/null 2>&1; then
	fail "depends/rpk should error when \$HOME/.local/bin/rpk is missing"
else
	ok "depends/rpk errors when \$HOME/.local/bin/rpk is missing"
fi

# install a fake rpk and re-run
cat >"$HOME/.local/bin/rpk" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$HOME/.local/bin/rpk"
if "$DEPENDS/rpk" >/dev/null 2>&1; then
	ok "depends/rpk succeeds when \$HOME/.local/bin/rpk is present"
else
	fail "depends/rpk errored when \$HOME/.local/bin/rpk is present"
fi

# -----------------------------------------------------------------------
# 3. depends/account: imports + installs in package-first form.
#    Cold cache → `import` then `account install`.
#    Warm cache (already in `rpk list`) → `account install` only.
#    The install MUST use the package-first form `rpk account install`
#    — the verb-first form `rpk install account` recurses into rpk's
#    cwd-based PACKAGE detection and loops forever.
# -----------------------------------------------------------------------

banner "depends/account"

# stubbed rpk that records its arguments and lets us control the
# `rpk list` output via $RPK_LIST.
cat >"$HOME/.local/bin/rpk" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$RPK_LOG"
case "$1" in
	list) cat "$RPK_LIST" 2>/dev/null || true ;;
	*)    ;;
esac
exit 0
EOF
chmod +x "$HOME/.local/bin/rpk"
export RPK_LOG="$TMP/rpk.log"
export RPK_LIST="$TMP/rpk-list.txt"

# cold cache: list returns empty → expect import + `account install`.
: >"$RPK_LOG"
: >"$RPK_LIST"
if "$DEPENDS/account" >/dev/null 2>&1 \
	&& grep -q '^import https://github.com/nostra124/account$' "$RPK_LOG" \
	&& grep -q '^account install$' "$RPK_LOG" \
	&& ! grep -q '^install ' "$RPK_LOG"; then
	ok "depends/account: cold cache → import + 'account install'"
else
	fail "depends/account: cold-cache log mismatch (got: $(tr '\n' '|' <"$RPK_LOG"))"
fi

# warm cache: list returns 'account' → expect `account install`, no import.
: >"$RPK_LOG"
echo account >"$RPK_LIST"
if "$DEPENDS/account" >/dev/null 2>&1 \
	&& ! grep -q '^import' "$RPK_LOG" \
	&& grep -q '^account install$' "$RPK_LOG" \
	&& ! grep -q '^install ' "$RPK_LOG"; then
	ok "depends/account: warm cache → 'account install' only, no import"
else
	fail "depends/account: warm-cache log mismatch (got: $(tr '\n' '|' <"$RPK_LOG"))"
fi

# -----------------------------------------------------------------------
# summary
# -----------------------------------------------------------------------

printf '\nin-container summary: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
