#!/bin/bash

set -euo pipefail

# Function to check if a command exists
is_command_installed() {
    command -v "$1" &>/dev/null
}

# Install Homebrew if not already installed
install_homebrew() {
    if ! is_command_installed brew; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

# Install a Homebrew formula
install_formula() {
    if ! brew list --formula | grep -q "^$1$"; then
        echo "Installing formula: $1"
        brew install "$1"
    else
        echo "Formula already installed: $1"
    fi
}

# Install a Homebrew cask
install_cask() {
    local app="$1"
    local identifier="$2"
    if ! mdfind "kMDItemCFBundleIdentifier == '$identifier'" | grep -q .; then
        echo "Installing cask: $app"
        brew install --cask "$app" --no-quarantine
    else
        echo "Cask already installed: $app"
    fi
}

# Install Oh My Zsh and plugins
install_oh_my_zsh_and_plugins() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        echo "Oh My Zsh already installed."
    fi

    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # Install plugins
    echo "Installing Zsh plugins..."

    [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && \
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

    [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

    [[ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]] && \
        git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"

    [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ]] && \
        git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete "$ZSH_CUSTOM/plugins/zsh-autocomplete"

    # Enable plugins in .zshrc
    echo "Enabling Zsh plugins in ~/.zshrc..."

    if grep -q "^plugins=" "$HOME/.zshrc"; then
        sed -i '' 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)/' "$HOME/.zshrc"
    else
        echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)" >> "$HOME/.zshrc"
    fi
}

### --- START INSTALL PROCESS ---

install_homebrew

# Install casks
echo "Installing cask apps..."
install_cask iterm2 com.googlecode.iterm2
install_cask intellij-idea com.jetbrains.intellij
install_cask firefox org.mozilla.firefox

# Install Zsh and set it as default shell if needed
if [[ "$SHELL" != *zsh* ]]; then
    install_formula zsh
    sudo chsh -s /bin/zsh
fi

# Install Oh My Zsh and Zsh plugins
install_oh_my_zsh_and_plugins

# Install Homebrew formulas
echo "Installing formulas..."
FORMULAS=(
    aom aribb24 aws-cdk awscli azure-cli brotli ca-certificates cairo cffi cjson cryptography
    dav1d flac fontconfig freetype frei0r fribidi gmp gnupg gnutls graphite2 harfbuzz highway icu4c
    imath jpeg-turbo jpeg-xl krb5 lame leptonica libarchive libass libassuan libbluray libevent
    libgcrypt libgpg-error libidn2 libksba libnghttp2 libogg libpq librist libsamplerate libsoxr
    libsodium libssh libtasn1 libtiff libunibreak libusb libuv libvidstab libvmaf libvorbis libvpx
    libxau libxcb libxdmcp libxext libxrender little-cms2 lzo mbedtls mpdecimal mpg123 nettle node
    opencore-amr openexr openjpeg openssl@3 opus p11-kit pango pcre2 pinentry pipx pixman postgresql@15
    psql2csv pycparser python@3.11 python@3.12 rav1e readline rubberband snappy sops speex sqlite
    srt svt-av1 terraform terragrunt tesseract theora unbound x264 x265 xvid xz yarn zimg zstd xorgproto
)

for pkg in "${FORMULAS[@]}"; do
    install_formula "$pkg"
done

echo "✅ macOS setup complete!"
echo "💡 Restart your terminal or run 'exec zsh' to load new Zsh environment."