#!/bin/bash

# Function to print an error and exit the script
error_exit() {
  echo "Error: $1"
  exit 1
}

# Function to check if Homebrew is installed
check_brew() {
  echo "Checking for Homebrew..."
  if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error_exit "Failed to install Homebrew."
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/valejojohnson/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo "Homebrew is already installed."
  fi
}

# Function to check if an application is installed via `mdfind`
is_app_installed() {
  mdfind "kMDItemCFBundleIdentifier == '$1'" | grep -q .
}

# Function to check if a Homebrew package is installed
is_brew_package_installed() {
  brew list --formula | grep -q "^$1\$"
}

# Function to install Homebrew formulae if not already installed
install_brew_package() {
  if is_brew_package_installed "$1"; then
    echo "$1 is already installed."
  else
    echo "$1 is not installed. Installing $1..."
    brew install "$1" || error_exit "Failed to install $1."
  fi
}

# Function to check and install a Homebrew cask package (for applications)
install_cask_app() {
  local app_name=$1
  local bundle_id=$2
  echo "Checking for $app_name..."
  if is_app_installed "$bundle_id"; then
    echo "$app_name is already installed."
  else
    echo "$app_name is not installed. Installing $app_name..."
    brew install --cask "$app_name" --no-quarantine || error_exit "Failed to install $app_name."
  fi
}

# Function to check if Zsh is installed and set as the default shell
check_zsh() {
  echo "Checking for Zsh..."
  if [[ "$SHELL" == */zsh ]]; then
    echo "Zsh is already the default shell."
  else
    echo "Zsh is not installed or not the default shell. Installing Zsh..."
    brew install zsh || error_exit "Failed to install Zsh."
    chsh -s "$(which zsh)" || error_exit "Failed to change the default shell to Zsh."
  fi
}

# Function to install ChatGPT desktop app
install_chatgpt_app() {
  local app_name="chatgpt"
  local bundle_id="com.openai.chatgpt" # Replace with the actual bundle identifier if different
  echo "Checking for ChatGPT app..."
  if is_app_installed "$bundle_id"; then
    echo "ChatGPT app is already installed."
  else
    echo "ChatGPT app is not installed. Installing ChatGPT app..."
    brew install --cask "$app_name" --no-quarantine || error_exit "Failed to install ChatGPT app."
  fi
}

# Check for Homebrew
check_brew

# Install applications using Homebrew casks
install_cask_app "iterm2" "com.googlecode.iterm2"
install_cask_app "intellij-idea" "com.jetbrains.intellij"
install_cask_app "docker" "com.docker.docker"
install_cask_app "firefox" "org.mozilla.firefox"
install_chatgpt_app

# Check and install Zsh if necessary
check_zsh

# Homebrew packages to install
PACKAGES=(
  aom ca-certificates flac glib highway kubernetes-cli libbluray libnghttp2 libsodium libusb libxau lzo opencore-amr pcre2 python@3.11 sops tesseract xvid
  aribb24 cairo fontconfig gmp icu4c lame libevent libogg libsoxr libuv libxcb mbedtls openexr pinentry python@3.12 speex theora xz
  aws-cdk cffi freetype gnupg imath leptonica libgcrypt libpng libssh libvidstab libxdmcp mpdecimal openjpeg pipx pixman readline srt sqlite unbound yarn
  awscli cjson frei0r gnutls jpeg-turbo libarchive libgpg-error libpq libtasn1 libvmaf libxext mpg123 openssl@3 p11-kit psql2csv rubberband svt-av1 x264 zimg
  azure-cli cryptography fribidi graphite2 jpeg-xl libass libidn2 librist libtiff libvorbis libxrender nettle opus postgresql@15 rav1e snappy terraform x265 zstd
  brotli dav1d gettext harfbuzz krb5 libassuan libksba libsamplerate libunibreak libvpx little-cms2 node pango pycparser snappy terragrunt xorgproto
)

echo "Installing Homebrew packages..."
for PACKAGE in "${PACKAGES[@]}"; do
  install_brew_package "$PACKAGE"
done

echo "Setup complete!"