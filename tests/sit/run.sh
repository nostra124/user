#!/bin/sh
# tests/sit/run.sh — orchestrate SIT runs across container images.
#
# Usage:
#   tests/sit/run.sh                 # default matrix
#   tests/sit/run.sh debian:stable   # one image
#   tests/sit/run.sh img1 img2 ...   # explicit list
#
# Per image we:
#   1. Launch a clean rootful container.
#   2. Bind-mount the repo read-only at /work.
#   3. Run tests/sit/in-container.sh.
#   4. Aggregate pass/fail and exit non-zero on any failure.
#
# Engine: podman by default; set SIT_ENGINE=docker to override.

set -eu

ENGINE="${SIT_ENGINE:-podman}"

DEFAULT_MATRIX="
debian:stable-slim
ubuntu:24.04
fedora:latest
archlinux:latest
alpine:latest
"

if ! command -v "$ENGINE" >/dev/null 2>&1; then
	echo "sit: container engine '$ENGINE' not found" >&2
	exit 2
fi

REPO=$(cd "$(dirname "$0")/../.." && pwd)

if [ "$#" -eq 0 ]; then
	# shellcheck disable=SC2086
	set -- $DEFAULT_MATRIX
fi

fails=0
total=0
for img in "$@"; do
	total=$((total + 1))
	printf '\n==> SIT: %s\n' "$img"
	if "$ENGINE" run --rm \
		-v "$REPO:/work:ro" \
		-w /work \
		"$img" \
		/work/tests/sit/in-container.sh; then
		printf '==> PASS: %s\n' "$img"
	else
		printf '==> FAIL: %s\n' "$img"
		fails=$((fails + 1))
	fi
done

printf '\nSIT summary: %d/%d passed\n' "$((total - fails))" "$total"
[ "$fails" -eq 0 ]
