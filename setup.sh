#!/usr/bin/env bash

# ============================================================
# Game Development Setup for Ubuntu 26.04 LTS
#
# Installs:
#   - Full system upgrade
#   - Git and Git LFS
#   - GCC, Clang, GDB and LLDB
#   - CMake, Ninja, Meson and pkg-config
#   - Python development tools
#   - Vulkan, OpenGL, SDL, OpenAL and FFmpeg development tools
#   - Latest stable Visual Studio Code via Microsoft APT repository
#   - Godot, Discord, Blender, Chromium, Steam, Krita and OBS
#     via Flatpak/Flathub
#   - Recommended VS Code extensions
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh
#
# Do NOT run with:
#   sudo ./setup.sh
# ============================================================

set -Eeuo pipefail

# ------------------------------------------------------------
# Language detection
# ------------------------------------------------------------

SYSTEM_LOCALE="${LC_ALL:-${LC_MESSAGES:-${LANG:-en_US.UTF-8}}}"
SYSTEM_LANGUAGE="${SYSTEM_LOCALE%%[_@.]*}"

if [[ "${SYSTEM_LANGUAGE,,}" == "de" ]]; then
    USE_GERMAN=true
else
    USE_GERMAN=false
fi

text() {
    local german="$1"
    local english="$2"

    if [[ "$USE_GERMAN" == true ]]; then
        printf '%s' "$german"
    else
        printf '%s' "$english"
    fi
}

# ------------------------------------------------------------
# Terminal output
# ------------------------------------------------------------

if [[ -t 1 ]]; then
    readonly BLUE='\033[1;34m'
    readonly GREEN='\033[1;32m'
    readonly YELLOW='\033[1;33m'
    readonly RED='\033[1;31m'
    readonly RESET='\033[0m'
else
    readonly BLUE=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly RED=''
    readonly RESET=''
fi

info() {
    printf '\n%b==> %s%b\n' "$BLUE" "$1" "$RESET"
}

success() {
    printf '%b✓ %s%b\n' "$GREEN" "$1" "$RESET"
}

warning() {
    printf '%b! %s%b\n' "$YELLOW" "$1" "$RESET" >&2
}

error() {
    printf '%b✗ %s%b\n' "$RED" "$1" "$RESET" >&2
}

fatal() {
    error "$1"
    exit 1
}

on_error() {
    local exit_code=$?
    local line_number="${1:-unknown}"

    error "$(text \
        "Das Setup ist in Zeile ${line_number} fehlgeschlagen." \
        "The setup failed at line ${line_number}.")"

    exit "$exit_code"
}

trap 'on_error "$LINENO"' ERR

# ------------------------------------------------------------
# Checks
# ------------------------------------------------------------

if [[ "$EUID" -eq 0 ]]; then
    fatal "$(text \
        "Starte dieses Skript als normaler Benutzer, nicht mit sudo." \
        "Run this script as a normal user, not with sudo.")"
fi

if [[ ! -r /etc/os-release ]]; then
    fatal "$(text \
        "/etc/os-release konnte nicht gelesen werden." \
        "/etc/os-release could not be read.")"
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ "${ID:-}" != "ubuntu" ]]; then
    fatal "$(text \
        "Dieses Skript unterstützt nur Ubuntu. Erkannt: ${PRETTY_NAME:-unbekannt}" \
        "This script supports Ubuntu only. Detected: ${PRETTY_NAME:-unknown}")"
fi

if [[ "${VERSION_ID:-}" != "26.04" ]]; then
    warning "$(text \
        "Dieses Skript wurde für Ubuntu 26.04 entwickelt. Erkannt: ${PRETTY_NAME:-unbekannt}" \
        "This script was designed for Ubuntu 26.04. Detected: ${PRETTY_NAME:-unknown}")"
fi

ARCHITECTURE="$(dpkg --print-architecture)"

if [[ "$ARCHITECTURE" != "amd64" ]]; then
    fatal "$(text \
        "Dieses Skript unterstützt derzeit nur amd64/x86-64. Erkannt: ${ARCHITECTURE}" \
        "This script currently supports amd64/x86-64 only. Detected: ${ARCHITECTURE}")"
fi

if ! command -v sudo >/dev/null 2>&1; then
    fatal "$(text \
        "sudo ist nicht installiert." \
        "sudo is not installed.")"
fi

if ! sudo -v; then
    fatal "$(text \
        "sudo-Berechtigung wurde nicht erteilt." \
        "sudo permission was not granted.")"
fi

# Keep the sudo timestamp alive while the script runs.
keep_sudo_alive() {
    while true; do
        sudo -n true
        sleep 50
        kill -0 "$$" 2>/dev/null || exit
    done
}

keep_sudo_alive &
SUDO_KEEPALIVE_PID=$!

cleanup() {
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
}

trap cleanup EXIT

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------

apt_package_exists() {
    local package="$1"

    apt-cache show "$package" >/dev/null 2>&1
}

install_available_apt_packages() {
    local available_packages=()
    local missing_packages=()
    local package

    for package in "$@"; do
        if apt_package_exists "$package"; then
            available_packages+=("$package")
        else
            missing_packages+=("$package")
        fi
    done

    if (( ${#available_packages[@]} > 0 )); then
        sudo DEBIAN_FRONTEND=noninteractive apt install -y \
            "${available_packages[@]}"
    fi

    if (( ${#missing_packages[@]} > 0 )); then
        warning "$(text \
            "Diese optionalen Pakete wurden nicht gefunden und übersprungen: ${missing_packages[*]}" \
            "These optional packages were not found and were skipped: ${missing_packages[*]}")"
    fi
}

install_flatpak_app() {
    local app_id="$1"
    local app_name="$2"

    if flatpak info --system "$app_id" >/dev/null 2>&1; then
        success "$(text \
            "${app_name} ist bereits installiert." \
            "${app_name} is already installed.")"
    else
        info "$(text \
            "Installiere ${app_name} …" \
            "Installing ${app_name}…")"

        sudo flatpak install --system --noninteractive -y flathub "$app_id"
    fi
}

install_vscode_extension() {
    local extension_id="$1"

    if code --list-extensions 2>/dev/null |
        grep -Fxiq "$extension_id"; then
        success "$(text \
            "VS-Code-Erweiterung bereits installiert: ${extension_id}" \
            "VS Code extension already installed: ${extension_id}")"
    else
        code --install-extension "$extension_id" --force
    fi
}

# ------------------------------------------------------------
# Start
# ------------------------------------------------------------

info "$(text \
    "Starte die Einrichtung der Entwicklungsumgebung." \
    "Starting development environment setup.")"

printf '%s\n' "$(text \
    "System: ${PRETTY_NAME}" \
    "System: ${PRETTY_NAME}")"

printf '%s\n' "$(text \
    "Architektur: ${ARCHITECTURE}" \
    "Architecture: ${ARCHITECTURE}")"

printf '%s\n' "$(text \
    "Erkannte Sprache: Deutsch" \
    "Detected language: English")"

# ------------------------------------------------------------
# System upgrade
# ------------------------------------------------------------

info "$(text \
    "Aktualisiere die Paketlisten." \
    "Updating package lists.")"

sudo apt update

info "$(text \
    "Installiere alle verfügbaren Systemaktualisierungen." \
    "Installing all available system updates.")"

sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y

# ------------------------------------------------------------
# Enable additional Ubuntu repositories
# ------------------------------------------------------------

info "$(text \
    "Aktiviere die benötigten Ubuntu-Paketquellen." \
    "Enabling required Ubuntu repositories.")"

sudo apt install -y software-properties-common

sudo add-apt-repository -y universe
sudo add-apt-repository -y multiverse

sudo apt update

# ------------------------------------------------------------
# Base tools
# ------------------------------------------------------------

info "$(text \
    "Installiere allgemeine Werkzeuge." \
    "Installing general tools.")"

sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    ca-certificates \
    curl \
    wget \
    gnupg \
    unzip \
    zip \
    tar \
    xz-utils \
    jq \
    git \
    git-lfs \
    openssh-client \
    rsync \
    file \
    desktop-file-utils \
    xdg-utils \
    gvfs \
    libglib2.0-bin

git lfs install

# ------------------------------------------------------------
# Development tools
# ------------------------------------------------------------

info "$(text \
    "Installiere Compiler, Debugger und Build-Werkzeuge." \
    "Installing compilers, debuggers and build tools.")"

sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    build-essential \
    gcc \
    g++ \
    clang \
    clang-format \
    clang-tidy \
    gdb \
    lldb \
    cmake \
    cmake-curses-gui \
    ninja-build \
    meson \
    make \
    pkg-config \
    ccache \
    valgrind

# ------------------------------------------------------------
# Python tools
# ------------------------------------------------------------

info "$(text \
    "Installiere Python-Werkzeuge." \
    "Installing Python tools.")"

sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    pipx

pipx ensurepath || true

# ------------------------------------------------------------
# Game-development libraries
# ------------------------------------------------------------

info "$(text \
    "Installiere Bibliotheken für Spieleentwicklung." \
    "Installing game-development libraries.")"

sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    mesa-utils \
    libvulkan-dev \
    vulkan-tools \
    glslang-tools \
    libopenal-dev \
    libsndfile1-dev \
    libasound2-dev \
    libpulse-dev \
    libx11-dev \
    libxext-dev \
    libxrandr-dev \
    libxinerama-dev \
    libxcursor-dev \
    libxi-dev \
    libwayland-dev \
    libxkbcommon-dev \
    libudev-dev \
    libdbus-1-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libssl-dev \
    zlib1g-dev \
    ffmpeg

# SDL package names can vary by Ubuntu release.
install_available_apt_packages \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libsdl2-ttf-dev \
    libsdl3-dev \
    libsdl3-image-dev \
    libsdl3-mixer-dev \
    libsdl3-ttf-dev

# ------------------------------------------------------------
# Microsoft Visual Studio Code repository
# ------------------------------------------------------------

info "$(text \
    "Richte das offizielle Microsoft-Repository für VS Code ein." \
    "Configuring the official Microsoft repository for VS Code.")"

readonly MICROSOFT_KEYRING="/usr/share/keyrings/microsoft.gpg"
readonly VSCODE_SOURCE="/etc/apt/sources.list.d/vscode.sources"
readonly VSCODE_PREFERENCES="/etc/apt/preferences.d/code"

TEMP_KEY="$(mktemp)"

wget -qO "$TEMP_KEY" \
    "https://packages.microsoft.com/keys/microsoft.asc"

gpg --batch --yes --dearmor \
    --output "${TEMP_KEY}.gpg" \
    "$TEMP_KEY"

sudo install \
    -o root \
    -g root \
    -m 0644 \
    "${TEMP_KEY}.gpg" \
    "$MICROSOFT_KEYRING"

rm -f "$TEMP_KEY" "${TEMP_KEY}.gpg"

sudo tee "$VSCODE_SOURCE" >/dev/null <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: ${ARCHITECTURE}
Signed-By: ${MICROSOFT_KEYRING}
EOF

# Prefer Microsoft's package if another repository also provides "code".
sudo tee "$VSCODE_PREFERENCES" >/dev/null <<'EOF'
Package: code
Pin: origin "packages.microsoft.com"
Pin-Priority: 9999
EOF

sudo apt update

info "$(text \
    "Installiere die neueste stabile Version von VS Code." \
    "Installing the latest stable version of VS Code.")"

sudo DEBIAN_FRONTEND=noninteractive apt install -y code

# ------------------------------------------------------------
# Flatpak and Flathub
# ------------------------------------------------------------

info "$(text \
    "Installiere Flatpak." \
    "Installing Flatpak.")"

sudo DEBIAN_FRONTEND=noninteractive apt install -y flatpak

# Install graphical Flatpak integration when available.
install_available_apt_packages \
    gnome-software-plugin-flatpak \
    plasma-discover-backend-flatpak

info "$(text \
    "Richte Flathub ein." \
    "Configuring Flathub.")"

sudo flatpak remote-add \
    --system \
    --if-not-exists \
    flathub \
    "https://dl.flathub.org/repo/flathub.flatpakrepo"

sudo flatpak update \
    --system \
    --noninteractive \
    -y \
    --appstream

# ------------------------------------------------------------
# Desktop applications
# ------------------------------------------------------------

install_flatpak_app \
    "org.godotengine.Godot" \
    "Godot"

install_flatpak_app \
    "com.discordapp.Discord" \
    "Discord"

install_flatpak_app \
    "org.blender.Blender" \
    "Blender"

install_flatpak_app \
    "org.chromium.Chromium" \
    "Chromium"

install_flatpak_app \
    "com.valvesoftware.Steam" \
    "Steam"

install_flatpak_app \
    "org.kde.krita" \
    "Krita"

install_flatpak_app \
    "com.obsproject.Studio" \
    "OBS Studio"

# ------------------------------------------------------------
# VS Code extensions
# ------------------------------------------------------------

info "$(text \
    "Installiere empfohlene VS-Code-Erweiterungen." \
    "Installing recommended VS Code extensions.")"

readonly VSCODE_EXTENSIONS=(
    "geequlim.godot-tools"
    "ms-vscode.cpptools"
    "ms-vscode.cmake-tools"
    "ms-vscode.makefile-tools"
    "ms-python.python"
    "ms-python.debugpy"
    "ms-dotnettools.csharp"
    "eamodio.gitlens"
    "usernamehw.errorlens"
    "EditorConfig.EditorConfig"
)

for extension in "${VSCODE_EXTENSIONS[@]}"; do
    install_vscode_extension "$extension"
done

# ------------------------------------------------------------
# Useful defaults
# ------------------------------------------------------------

info "$(text \
    "Richte einige sinnvolle Entwickler-Standardeinstellungen ein." \
    "Configuring useful development defaults.")"

# Register VS Code as a possible system editor.
sudo update-alternatives \
    --install \
    /usr/bin/editor \
    editor \
    /usr/bin/code \
    20

# Raise the file-watcher limit for larger game projects.
sudo tee /etc/sysctl.d/60-game-development.conf >/dev/null <<'EOF'
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=1024
EOF

sudo sysctl --system >/dev/null

# ------------------------------------------------------------
# Final updates and checks
# ------------------------------------------------------------

info "$(text \
    "Aktualisiere installierte Flatpak-Anwendungen." \
    "Updating installed Flatpak applications.")"

sudo flatpak update \
    --system \
    --noninteractive \
    -y

info "$(text \
    "Entferne nicht mehr benötigte APT-Pakete." \
    "Removing unused APT packages.")"

sudo DEBIAN_FRONTEND=noninteractive apt autoremove -y

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

printf '\n%b============================================================%b\n' \
    "$GREEN" "$RESET"

printf '%b%s%b\n' \
    "$GREEN" \
    "$(text \
        "Die Entwicklungsumgebung wurde erfolgreich eingerichtet." \
        "The development environment was configured successfully.")" \
    "$RESET"

printf '%b============================================================%b\n\n' \
    "$GREEN" "$RESET"

printf '%s\n' "$(text \
    "Installierte Hauptprogramme:" \
    "Main applications installed:")"

printf '  - Visual Studio Code: %s\n' \
    "$(code --version 2>/dev/null | head -n 1 || echo unknown)"

printf '  - Godot:     flatpak run org.godotengine.Godot\n'
printf '  - Discord:   flatpak run com.discordapp.Discord\n'
printf '  - Blender:   flatpak run org.blender.Blender\n'
printf '  - Chromium:  flatpak run org.chromium.Chromium\n'
printf '  - Steam:     flatpak run com.valvesoftware.Steam\n'
printf '  - Krita:     flatpak run org.kde.krita\n'
printf '  - OBS:       flatpak run com.obsproject.Studio\n'

printf '\n%s\n' "$(text \
    "Bitte melde dich einmal ab und wieder an oder starte den PC neu, damit alle Menüeinträge und Umgebungsänderungen sicher übernommen werden." \
    "Please log out and back in once, or restart the computer, so all menu entries and environment changes are applied.")"
