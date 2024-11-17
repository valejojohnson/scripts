#!/bin/bash

set -euo pipefail

# Function to check if a command exists
is_command_installed() {
    command -v "$1" &>/dev/null
}

# Function to check if an application is installed via `mdfind`
is_app_installed() {
    mdfind "kMDItemCFBundleIdentifier == '$1'" | grep -q . 2>/dev/null
}

# Function to check if a Homebrew package is installed
is_brew_package_installed() {
    brew list --formula 2>/dev/null | grep -q "^$1$"
}

# Generic installation function for Homebrew formulae and casks
install_brew() {
    local type=$1
    local name=$2
    local identifier=${3:-}
    shift 3
    case $type in
        formula)
            if ! is_brew_package_installed "$name"; then
                echo "Installing $name..."
                brew install "$name" &
            fi
            ;;
        cask)
            if ! is_app_installed "$identifier"; then
                echo "Installing $name..."
                brew install --cask "$name" "$@" &
            fi
            ;;
        *)
            echo "Unknown type: $type" >&2
            exit 1
            ;;
    esac
}

# Install Homebrew if not installed
if ! is_command_installed brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install cask applications
declare -A CASKS=(
    [iterm2]="com.googlecode.iterm2"
    [intellij-idea]="com.jetbrains.intellij"
    [docker]="com.docker.docker"
    [firefox]="org.mozilla.firefox"
)

echo "Installing cask applications..."
for cask in "${!CASKS[@]}"; do
    install_brew cask "$cask" "${CASKS[$cask]}" --no-quarantine
done

# Ensure Zsh is installed and set as default shell
if [[ "$SHELL" != *"zsh"* ]]; then
    echo "Installing Zsh..."
    install_brew formula zsh
    sudo chsh -s /bin/zsh
fi

# Homebrew formulae to install
PACKAGES=(
    aom ca-certificates flac glib highway kubernetes-cli libbluray libnghttp2 libsodium libusb libxau lzo opencore-amr pcre2 python@3.11 sops tesseract xvid
    aribb24 cairo fontconfig gmp icu4c lame libevent libogg libsoxr libuv libxcb mbedtls openexr pinentry python@3.12 speex theora xz
    aws-cdk cffi freetype gnupg imath leptonica libgcrypt libpng libssh libvidstab libxdmcp mpdecimal openjpeg pipx pixman readline srt sqlite unbound yarn
    awscli cjson frei0r gnutls jpeg-turbo libarchive libgpg-error libpq libtasn1 libvmaf libxext mpg123 openssl@3 p11-kit psql2csv rubberband svt-av1 x264 zimg
    azure-cli cryptography fribidi graphite2 jpeg-xl libass libidn2 librist libtiff libvorbis libxrender nettle opus postgresql@15 rav1e snappy terraform x265 zstd
    brotli dav1d gettext harfbuzz krb5 libassuan libksba libsamplerate libunibreak libvpx little-cms2 node pango pycparser snappy terragrunt xorgproto
)

echo "Installing Homebrew formulae..."
for package in "${PACKAGES[@]}"; do
    install_brew formula "$package"
done

wait

echo "Setup complete!"