#!/bin/bash
# User configuration for bash startup modules.
# Edit this file to enable/disable modules or set versions.
# Sourced by every module in ~/.local/etc/bash/startup.d/*/ before acting.

# ---------------------------------------------------------------------------
# Platform
# ---------------------------------------------------------------------------
# Both can be enabled; they prepend to PATH in order (macos loads first).
USER_MACPORTS_ENABLED=1
USER_BREW_ENABLED=1

# Override auto-detected brew prefix (normally /opt/homebrew or /usr/local)
#USER_BREW_PREFIX=/opt/homebrew

# Override macports prefix
#USER_MACPORTS_PREFIX=/opt/local

# ---------------------------------------------------------------------------
# Languages & runtimes
# ---------------------------------------------------------------------------
# Set to 0 to skip a language entirely
USER_NODE_ENABLED=1
USER_NODE_VERSION=20

USER_PYTHON_ENABLED=1
USER_GO_ENABLED=1
USER_GO_ROOT=

USER_JAVA_ENABLED=1
USER_RUBY_ENABLED=0
USER_PERL_ENABLED=1
USER_RUST_ENABLED=1

# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------
USER_Taskwarrior_ENABLED=1
USER_TAILSCALE_ENABLED=1

# ---------------------------------------------------------------------------
# Disabled modules (space-separated list of filenames)
# Example: USER_DISABLED="ruby cygwin wsl iptables_block_ip"
USER_DISABLED=""
