#!/bin/bash

# Enable error handling and verbose output
set -e
set -o pipefail
exec > >(tee -i setup.log) 2>&1

##############################################
### Helper Functions
##############################################

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to install a package if it doesn't exist
install_if_missing() {
  local package=$1
  local install_command=$2

  if ! command_exists "$package"; then
    echo "  ↳ Installing $package..."
    eval "$install_command"
  else
    echo "  ↳ $package already installed."
  fi
}

# Function to configure a default setting if it exists
configure_default() {
  local domain=$1
  local key=$2
  local value=$3

  if defaults read "$domain" "$key" >/dev/null 2>&1; then
    echo "  ↳ Configuring $domain $key..."
    defaults write "$domain" "$key" "$value"
  else
    echo "  ↳ $domain $key does not exist, skipping..."
  fi
}

##############################################
### System Configuration
##############################################
configure_system() {
  echo "⚙️ Configuring System Settings..."

  # Clear apps and folders from the Dock if they exist
  configure_default com.apple.dock persistent-apps ""
  configure_default com.apple.dock persistent-others ""

  # Apple Silicon specific setup
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo "  ↳ Installing Rosetta 2..."
    sudo softwareupdate --install-rosetta --agree-to-license
  fi

  # System identity
  sudo scutil --set ComputerName "eRave"
  sudo scutil --set HostName "eRave"
  sudo scutil --set LocalHostName "eRave"

  # UI Preferences
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock mineffect -string "scale"
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.controlcenter BatteryShowPercentage -bool TRUE

  # Security settings
  defaults write com.apple.screensaver askForPassword -bool true
  defaults write com.apple.screensaver askForPasswordDelay -int 0

  # Power management
  sudo pmset -b displaysleep 60
  sudo pmset -c displaysleep 60

  # Keyboard and Input
  defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
  defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
  defaults write -g NSAutomaticCapitalizationEnabled -bool false
  defaults write -g KeyRepeat -int 1
  defaults write -g InitialKeyRepeat -int 15

  # Mouse Settings
  defaults write -g com.apple.mouse.scaling -float 1.05
  defaults write -g com.apple.mouse.scaling -float -1

  # Apply changes
  killall SystemUIServer Dock Finder
}

##############################################
### Package Management Setup
##############################################
setup_package_management() {
  echo "📦 Setting Up Package Management..."

  # Install Homebrew
  install_if_missing brew '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # Install MAS (Mac App Store CLI)
  install_if_missing mas 'brew install mas'

  # Configure auto-updates (only if not already running)
  brew install pinentry-mac
  brew tap domt4/autoupdate

  if brew autoupdate status | grep -q "running"; then
    echo "  ↳ brew autoupdate is already running, skipping..."
  else
    echo "  ↳ Starting brew autoupdate..."
    brew autoupdate start 43200 --cleanup --upgrade --immediate --sudo
  fi
}

##############################################
### Display Configuration
##############################################
configure_display_settings() {
  echo "🖥️ Configuring Display Settings..."

  # Install displayplacer if not already installed
  install_if_missing displayplacer 'brew install jakehilborn/jakehilborn/displayplacer'

  # Set specific display configuration
  echo "  ↳ Applying display configuration..."
  displayplacer "id:37D8832A-2D66-02CA-B9F7-8F30A301B230 res:1440x900 hz:60 color_depth:8 enabled:true scaling:on origin:(0,0) degree:0"

  # Verify configuration
  if displayplacer list | grep -q "1680x1050"; then
    echo "  ↳ Display configuration verified successfully"
  else
    echo "  ↳ Warning: Display configuration might not have applied correctly"
    echo "  ↳ Check available resolutions with: displayplacer list"
  fi
}

##############################################
### Xcode Installation (Core)
##############################################
install_xcode() {
  echo "🛠️ Installing Xcode..."

  if [ ! -d "/Applications/Xcode.app" ]; then
    # Ensure App Store authentication
    if ! mas account >/dev/null 2>&1; then
      echo "  ↳ Please sign in to App Store when prompted..."
      open -a "App Store"
      read -n1 -p "Press any key when you've signed in to continue..."
    fi

    # Install Xcode (App Store ID: 497799835)
    echo "  ↳ Starting Xcode installation (this may take 30+ minutes)..."
    mas install 497799835

    # Wait for installation
    while [ ! -d "/Applications/Xcode.app" ]; do
      echo "  ↳ Waiting for Xcode installation to complete..."
      sleep 60
    done

    # Post-install setup
    echo "  ↳ Configuring Xcode..."
    sudo xcode-select --switch /Applications/Xcode.app
    sudo xcodebuild -license accept
    sudo xcodebuild -runFirstLaunch
  else
    echo "  ↳ Xcode already installed at /Applications/Xcode.app"
  fi
}

##############################################
### Development Environment Setup
##############################################
setup_development_environment() {
  echo "👨💻 Setting Up Development Environment..."

  # JavaScript Ecosystem
  brew install node pnpm oven-sh/bun/bun

  # Python Environment
  brew install python visidata

  # Editors and tools
  brew install neovim tmux ripgrep btop

  # PHP/Laravel
  /bin/bash -c "$(curl -fsSL https://php.new/install/mac)"
}

##############################################
### Mobile Development Setup
##############################################
setup_mobile_development() {
  echo "📱 Setting Up Mobile Development..."

  # Flutter installation
  brew install --cask flutter

  # Chrome installation
  brew install --cask google-chrome

  # Android Studio
  brew install --cask android-studio temurin android-commandlinetools
  yes | sdkmanager --licenses
  sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0 emulator"

  # Android licenses
  yes | flutter doctor --android-licenses

  # CocoaPods
  brew install cocoapods

  # Verify setup
  flutter doctor
}

##############################################
### Application Installation
##############################################
install_applications() {
  echo "📦 Installing Applications..."

  # Browsers and communication
  brew install --cask brave-browser signal

  # Development tools
  brew install --cask android-studio kitty

  # Media tools
  brew install --cask obs

  # Utilities
  brew install --cask nikitabobko/tap/aerospace

  # JetBrains Nerd Font Mono
  brew install --cask font-jetbrains-mono-nerd-font

  # Gather
  brew install --cask gather

  # AI
  brew install --cask ollama chatbox
}

##############################################
### Shell Environment Setup
##############################################
setup_shell_environment() {
  echo "🐚 Configuring Shell Environment..."

  # Oh My Zsh
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  # Shell tools
  brew install zsh-syntax-highlighting zsh-autosuggestions eza zoxide fzf oh-my-posh yazi thefuck cava cmatrix pipes-sh

  # File SVG Viewer & FFMPEG Support
  brew install librsvg imagemagick chafa ffmpeg

  # PDF Support for Markdown to PDF
  brew install basictex pandoc

  # WebP
  brew install webp

  # UNRAR
  brew install carlocab/personal/unrar
}

##############################################
### Git & Dotfiles Configuration
##############################################
configure_git_and_dotfiles() {
  echo "🔧 Configuring Git & Dotfiles..."

  git config --global user.email "ezraravin@proton.me"
  git config --global user.name "MacBook Air M1"
  git config --global init.defaultBranch main

  # Dotfiles setup
  if [[ ! -d "$HOME/dotfiles" ]]; then
    git clone git@gitlab.com:ezraravinmateus/dotfiles.git "$HOME/dotfiles"
    rsync -a "$HOME/dotfiles/." "$HOME/"
    rm -rf "$HOME/dotfiles"
  fi
}

##############################################
### Top Menu Bar Configuration
##############################################
setup_ui_customization() {
  echo "🎨 Configuring UI Customizations..."

  # Install and start SketchyBar
  install_if_missing sketchybar 'brew install FelixKratz/formulae/sketchybar'

  # Start SketchyBar as a service
  brew services start sketchybar
}

##############################################
### Main Execution Flow
##############################################
main() {
  # Extend sudo timeout to 1 hour (3600 seconds)
  sudo -v
  while true; do
    sudo -n true
    sleep 300
    kill -0 "$$" || exit
  done 2>/dev/null &

  configure_system
  setup_package_management
  configure_display_settings
  install_xcode
  setup_development_environment
  setup_mobile_development
  install_applications
  setup_shell_environment
  configure_git_and_dotfiles
  setup_ui_customization

  echo "✅ Setup complete! Some changes may require a restart."
  echo "🔍 Review installation log: setup.log"
}

# Start the main process
main
