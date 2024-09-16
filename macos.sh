#!/bin/bash

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
    brew install "$1"
  fi
}

# Check if iTerm2 is installed
echo "Checking for iTerm2..."
if is_app_installed "com.googlecode.iterm2"; then
  echo "iTerm2 is already installed."
else
  echo "iTerm2 is not installed. Installing iTerm2..."
  brew install --cask iterm2
fi

# Check if zsh is installed
echo "Checking for Zsh..."
if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
  echo "Zsh is already the default shell."
else
  echo "Zsh is not installed or not the default shell. Installing Zsh..."
  brew install zsh
  chsh -s /bin/zsh
fi

# Check if Homebrew is installed
echo "Checking for Homebrew..."
if ! command -v brew &> /dev/null; then
  echo "Homebrew is not installed. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew is already installed."
fi

# Check if IntelliJ IDEA Ultimate (Apple Silicon version) is installed
echo "Checking for IntelliJ IDEA Ultimate (Apple Silicon)..."
if is_app_installed "com.jetbrains.intellij.ce"; then
  echo "IntelliJ IDEA Ultimate is already installed."
else
  echo "IntelliJ IDEA Ultimate is not installed. Installing IntelliJ IDEA Ultimate for Apple Silicon..."
  brew install --cask intellij-idea --no-quarantine
fi

# Check if Docker Desktop is installed
echo "Checking for Docker Desktop..."
if is_app_installed "com.docker.docker"; then
  echo "Docker Desktop is already installed."
else
  echo "Docker Desktop is not installed. Installing Docker Desktop..."
  brew install --cask docker
fi

# Check if Firefox is installed
echo "Checking for Firefox..."
if is_app_installed "org.mozilla.firefox"; then
  echo "Firefox is already installed."
else
  echo "Firefox is not installed. Installing Firefox..."
  brew install --cask firefox
fi

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
