
#!/usr/bin/env bash

# Install or update the latest stable GitHub Copilot CLI.
# Supported: Ubuntu, other Linux distributions, macOS.

set -Eeuo pipefail

INSTALLER_URL="https://gh.io/copilot-install"

log()  { printf '\n\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn() { printf '\n\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
die()  { printf '\n\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

log "GitHub Copilot CLI installer"

# Detect operating system
OS="$(uname -s)"
case "$OS" in
    Linux)
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            log "Detected Linux: ${PRETTY_NAME:-Linux}"
        else
            log "Detected Linux"
        fi
        ;;
    Darwin)
        log "Detected macOS"
        ;;
    *)
        die "Unsupported operating system: $OS"
        ;;
esac

# Check required tools
command -v curl >/dev/null 2>&1 ||
    die "curl is required. Install curl and retry."

command -v bash >/dev/null 2>&1 ||
    die "Bash is required."

# Select an installation prefix.
# Respect PREFIX if supplied; otherwise use a user-local directory.
if [ -z "${PREFIX:-}" ]; then
    PREFIX="${HOME}/.local"
fi

export PREFIX

log "Installation prefix: $PREFIX"
log "Downloading and running the official GitHub installer..."

# Install the latest stable version.
# The official installer handles the platform-specific executable.
curl -fsSL "$INSTALLER_URL" | bash

# Add the expected user-local executable directory to PATH
export PATH="${PREFIX}/bin:${HOME}/.local/bin:/usr/local/bin:$PATH"

# Verify installation
if command -v copilot >/dev/null 2>&1; then
    log "Installation successful."
    printf '\nInstalled version:\n'
    copilot --version

    printf '\nNext steps:\n'
    printf '  1. Run: copilot\n'
    printf '  2. Enter /login inside the CLI to authenticate.\n'
else
    warn "The installer completed, but 'copilot' was not found in PATH."
    warn "Check the installer output and your installation directory."
    warn "Try opening a new terminal, then run: copilot --version"
    exit 1
fi

log "Official documentation:"
printf '%s\n' \
  "https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/install-copilot-cli"

