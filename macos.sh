#!/usr/bin/env bash
# macos.sh - error-tolerant, always-latest bootstrapper (ASCII-only, Bash 3.2-safe)

# We intentionally do NOT use: set -e, set -u, or pipefail
# The script should never abort; it logs failures and continues.

LOGFILE="${LOGFILE:-$HOME/macos-bootstrap.log}"
: >"$LOGFILE"
START_TS="$(date +%s)"

# ----------------------------- Logging -----------------------------
color() { # color "31" "text" ; 31=red, 33=yellow, 36=cyan, 32=green
  printf "\033[%sm%s\033[0m" "$1" "$2"
}
info()  { printf "%s %s\n" "$(color '36' '[INFO]')"  "$*" | tee -a "$LOGFILE"; }
warn()  { printf "%s %s\n" "$(color '33' '[WARN]')"  "$*" | tee -a "$LOGFILE" >&2; }
err()   { printf "%s %s\n" "$(color '31' '[ERROR]')" "$*" | tee -a "$LOGFILE" >&2; }

# -------------------------- Error tracking -------------------------
ERRORS=()

log_error() {
  # usage: log_error "Description" [exit_code]
  local desc="${1:-<unknown step>}" code="${2:-1}"
  ERRORS+=("$desc (exit $code)")
  err "$desc failed (exit $code)"
}

run_step() {
  # usage: run_step "Description" command args...
  if [ "$#" -lt 2 ]; then
    log_error "run_step called without enough arguments" 1
    return 0
  fi
  local desc="$1"; shift
  info "$desc ..."
  local ec
  if "$@" >>"$LOGFILE" 2>&1; then
    ec=0
  else
    ec=$?
  fi
  if [ "$ec" -eq 0 ]; then
    info "$desc OK"
  else
    log_error "$desc" "$ec"
  fi
}

run_bg() {
  # usage: run_bg "Description" command args...
  if [ "$#" -lt 2 ]; then
    log_error "run_bg called without enough arguments" 1
    return 0
  fi
  local desc="$1"; shift
  ( run_step "$desc" "$@" ) &
}

wait_all() { wait; }

finish_report() {
  echo >>"$LOGFILE"
  echo "================= SUMMARY ($(date)) =================" | tee -a "$LOGFILE"
  local failures=${#ERRORS[@]}
  if [ "$failures" -gt 0 ]; then
    printf "%s\n" "$(color '31' "FAILURES: $failures")"
    local i
    for (( i=0; i<failures; i++ )); do
      echo " - ${ERRORS[$i]}" | tee -a "$LOGFILE"
    done
  else
    printf "%s\n" "$(color '32' 'All steps completed successfully')"
  fi
  local dur="$(( $(date +%s) - START_TS ))"
  echo "Duration: ${dur}s" | tee -a "$LOGFILE"
  echo "Log: $LOGFILE"
}
trap finish_report EXIT

# -------------------------- Sudo keep-alive -------------------------
if command -v sudo >/dev/null 2>&1; then
  run_step "Initialize sudo" sudo -v
  ( while true; do sudo -n true 2>/dev/null || true; sleep 60; done ) &
fi

# -------------------------- Xcode CLT -------------------------------
wait_for_xcode_clt() {
  if ! xcode-select -p >/dev/null 2>&1; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install >/dev/null 2>&1 || true
    # Wait for installation to complete
    until xcode-select -p >/dev/null 2>&1; do
      sleep 5
    done
    info "Xcode Command Line Tools installed"
  fi
}

run_step "Xcode Command Line Tools" wait_for_xcode_clt

# --------------------------- Homebrew -------------------------------
ARCH="$(uname -m)"
if [ "$ARCH" = "arm64" ]; then
  HOMEBREW_PREFIX="/opt/homebrew"
else
  HOMEBREW_PREFIX="/usr/local"
fi

install_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 0
  fi
  # shellenv for this session
  if [ -x "$HOMEBREW_PREFIX/bin/brew" ]; then
    eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
  elif command -v brew >/dev/null 2>&1; then
    eval "$("brew" shellenv)"
  fi
  brew update    || true
  brew upgrade   || true
  brew autoremove|| true
  brew cleanup -s|| true
}

# Map cask names to their .app bundle names for existence checking
get_app_name_for_cask() {
  case "$1" in
    iterm2)               echo "iTerm.app" ;;
    docker)               echo "Docker.app" ;;
    google-chrome)        echo "Google Chrome.app" ;;
    1password)            echo "1Password.app" ;;
    intellij-idea)        echo "IntelliJ IDEA.app" ;;
    *)                    echo "" ;;  # Unknown, will attempt install
  esac
}

brew_install_or_upgrade() { # formula or cask
  if [ "${1:-}" = "--cask" ]; then
    local type="cask"; shift
  else
    local type="formula"
  fi
  local name="$1"

  # For casks, check if already managed by brew or installed manually
  if [ "$type" = "cask" ]; then
    if brew list --cask "$name" >/dev/null 2>&1; then
      brew upgrade --cask "$name" || true
    else
      # Check if app is already installed outside Homebrew
      local app_name
      app_name="$(get_app_name_for_cask "$name")"
      if [ -n "$app_name" ] && [ -d "/Applications/$app_name" ]; then
        info "$name already installed at /Applications/$app_name (not via Homebrew), skipping"
        return 0
      fi
      brew install --cask "$name" || true
    fi
  else
    # Formula handling
    if brew list --formula "$name" >/dev/null 2>&1; then
      brew upgrade --formula "$name" || true
    else
      brew install --formula "$name" || true
    fi
  fi
}

run_step "Install/Update Homebrew" install_homebrew
add_font_tap() {
  if brew tap | grep -q "^homebrew/cask-fonts$"; then
    info "homebrew/cask-fonts already tapped"
  else
    brew tap homebrew/cask-fonts || true
  fi
}
run_step "Add Homebrew font tap" add_font_tap

# --------------------------- MAS helper -----------------------------
mas_install_or_upgrade() { # mas_install_or_upgrade <app_id> [name]
  local id="$1" name="${2:-$1}"
  if ! command -v mas >/dev/null 2>&1; then
    brew_install_or_upgrade mas || return 0
  fi
  if ! mas account >/dev/null 2>&1; then
    warn "Not signed into App Store; skipping MAS app: $name"
    return 0
  fi
  if mas list | awk '{print $1}' | grep -qx "$id"; then
    mas upgrade "$id" || true
  else
    mas install "$id" || true
  fi
}

# ------------------------- Zsh / plugins ----------------------------
ensure_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
  else
    if command -v omz >/dev/null 2>&1; then omz update || true; fi
  fi
}

git_clone_or_update() { # git_clone_or_update <repo_url> <dest_dir>
  local url="$1" dest="$2"
  if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only || true
  else
    git clone --depth=1 "$url" "$dest" || true
  fi
}

install_zsh_plugins() {
  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  git_clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  git_clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  git_clone_or_update https://github.com/zdharma-continuum/fast-syntax-highlighting "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
}

configure_zshrc() {
  local zshrc="$HOME/.zshrc"
  if [ ! -f "$zshrc" ]; then
    warn ".zshrc not found; skipping plugin configuration"
    return 0
  fi
  # Add plugins if not already configured
  if grep -q "^plugins=(" "$zshrc" && ! grep -q "zsh-autosuggestions" "$zshrc"; then
    # Replace the plugins line to include our plugins
    sed -i.bak 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions zsh-syntax-highlighting)/' "$zshrc" || true
    info "Updated .zshrc with zsh plugins"
  fi
}

ensure_default_shell_zsh() {
  if [ "${SHELL:-}" != "/bin/zsh" ]; then
    chsh -s /bin/zsh || true
  fi
}

# ------------------------- Git configuration -------------------------
configure_git() {
  # Set sensible defaults only if not already configured
  if [ -z "$(git config --global init.defaultBranch)" ]; then
    git config --global init.defaultBranch main
  fi
  if [ -z "$(git config --global pull.rebase)" ]; then
    git config --global pull.rebase true
  fi
  if [ -z "$(git config --global push.autoSetupRemote)" ]; then
    git config --global push.autoSetupRemote true
  fi
  # Set IntelliJ as editor if installed and no editor is configured
  if [ -z "$(git config --global core.editor)" ]; then
    if command -v idea >/dev/null 2>&1; then
      git config --global core.editor "idea --wait"
    else
      git config --global core.editor "vim"
    fi
  fi

  # Only prompt for user info if not already configured
  if [ -z "$(git config --global user.name)" ]; then
    printf "Git user.name: "
    read -r git_name
    if [ -n "$git_name" ]; then
      git config --global user.name "$git_name"
    fi
  else
    info "Git user.name already set: $(git config --global user.name)"
  fi
  if [ -z "$(git config --global user.email)" ]; then
    printf "Git user.email: "
    read -r git_email
    if [ -n "$git_email" ]; then
      git config --global user.email "$git_email"
    fi
  else
    info "Git user.email already set: $(git config --global user.email)"
  fi
}

# ------------------------- SSH key setup -----------------------------
setup_ssh_key() {
  local ssh_dir="$HOME/.ssh"
  local ssh_key="$ssh_dir/id_ed25519"

  # Ensure .ssh directory exists with correct permissions
  if [ ! -d "$ssh_dir" ]; then
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
  fi

  if [ ! -f "$ssh_key" ]; then
    info "Generating new SSH key..."
    ssh-keygen -t ed25519 -f "$ssh_key" -N "" || return 0

    # Start ssh-agent and add key
    eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
    ssh-add "$ssh_key" >/dev/null 2>&1 || true

    if [ -f "$ssh_key.pub" ]; then
      echo ""
      info "SSH public key:"
      cat "$ssh_key.pub"
      echo ""
      # Copy to clipboard on macOS
      if command -v pbcopy >/dev/null 2>&1; then
        pbcopy < "$ssh_key.pub"
        info "Public key copied to clipboard - add it to GitHub/GitLab"
      fi
    fi
  else
    info "SSH key already exists at $ssh_key"
  fi
}

# ------------------------- macOS defaults ----------------------------
# Helper to set a default only if not already set to the desired value
set_default_if_different() {
  local domain="$1" key="$2" type="$3" value="$4"
  local current
  current="$(defaults read "$domain" "$key" 2>/dev/null)" || current=""
  if [ "$current" != "$value" ]; then
    defaults write "$domain" "$key" "$type" "$value"
    return 0  # changed
  fi
  return 1  # no change
}

configure_macos_defaults() {
  local needs_finder_restart=false
  local needs_dock_restart=false

  # Keyboard: faster key repeat
  set_default_if_different NSGlobalDomain KeyRepeat -int 2 || true
  set_default_if_different NSGlobalDomain InitialKeyRepeat -int 15 || true

  # Finder: show hidden files
  if set_default_if_different com.apple.finder AppleShowAllFiles -bool true; then
    needs_finder_restart=true
  fi
  # Finder: show path bar
  if set_default_if_different com.apple.finder ShowPathbar -bool true; then
    needs_finder_restart=true
  fi
  # Finder: show status bar
  if set_default_if_different com.apple.finder ShowStatusBar -bool true; then
    needs_finder_restart=true
  fi
  # Finder: default to list view
  if set_default_if_different com.apple.finder FXPreferredViewStyle -string Nlsv; then
    needs_finder_restart=true
  fi

  # Dock: autohide
  if set_default_if_different com.apple.dock autohide -bool true; then
    needs_dock_restart=true
  fi
  # Dock: remove delay
  if set_default_if_different com.apple.dock autohide-delay -float 0; then
    needs_dock_restart=true
  fi

  # Screenshots: save to Desktop
  set_default_if_different com.apple.screencapture location -string "$HOME/Desktop" || true
  # Screenshots: disable shadow
  set_default_if_different com.apple.screencapture disable-shadow -bool true || true

  # Disable press-and-hold for keys (enable key repeat)
  set_default_if_different NSGlobalDomain ApplePressAndHoldEnabled -bool false || true

  # Only restart apps if settings actually changed
  if [ "$needs_finder_restart" = true ]; then
    killall Finder 2>/dev/null || true
  fi
  if [ "$needs_dock_restart" = true ]; then
    killall Dock 2>/dev/null || true
  fi
}

# ---------------------------- Install sets --------------------------
FORMULAS=(
  git gh wget curl jq yq tree coreutils findutils gnu-sed unzip
  python node pnpm yarn go rust terraform terragrunt awscli sops
)
CASKS=(
  iterm2 docker google-chrome 1password intellij-idea
)
MAS_APPS=(
  # "497799835 Xcode"
  # "409183694 Keynote"
)

for f in "${FORMULAS[@]}"; do
  run_bg "brew $f" brew_install_or_upgrade "$f"
done

for c in "${CASKS[@]}"; do
  run_bg "cask $c" brew_install_or_upgrade --cask "$c"
done

for entry in "${MAS_APPS[@]}"; do
  id="${entry%% *}"; name="${entry#* }"
  run_bg "mas $name" mas_install_or_upgrade "$id" "$name"
done

run_bg "Oh My Zsh" ensure_oh_my_zsh
run_bg "Zsh plugins" install_zsh_plugins
run_bg "Set default shell to zsh" ensure_default_shell_zsh
run_bg "macOS defaults" configure_macos_defaults

# Optional macOS updates, non-fatal
run_bg "softwareupdate --install --all" bash -lc 'softwareupdate --install --all || true'

wait_all

# Configure zshrc after Oh My Zsh and plugins are installed
run_step "Configure .zshrc plugins" configure_zshrc

run_step "brew cleanup" bash -lc 'brew cleanup -s || true'

# Interactive steps (require user input) - run at the end
info ""
info "=== Interactive Configuration ==="
run_step "Git configuration" configure_git
run_step "SSH key setup" setup_ssh_key

info "All queued steps finished."
# Summary is printed by the EXIT trap
