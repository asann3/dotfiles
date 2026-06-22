#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Cache sudo credentials for the duration of this script
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Install Homebrew if not present
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Add Homebrew to PATH (Apple Silicon: /opt/homebrew, Intel: /usr/local)
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
brew bundle --file="$DOTFILES/.Brewfile"

# Install Nix if not present
if ! command -v nix &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Symlinks (absolute source paths required)
link() { mkdir -p "$(dirname "$2")" && ln -sf "$DOTFILES/$1" "$2"; }
link .tmux.conf ~/.tmux.conf
link .vimrc ~/.vimrc
link .zshrc ~/.zshrc
link .config/karabiner/karabiner.json ~/.config/karabiner/karabiner.json
link .config/karabiner/assets/complex_modifications ~/.config/karabiner/assets/complex_modifications
link .zsh/.p10k.zsh ~/.p10k.zsh

# Personalize user.nix (BSD sed: runs before nix provides GNU sed)
sed -i '' "s/username/$(whoami)/g" user.nix
sed -i '' "s/hostname/$(hostname -s)/g" user.nix
git update-index --skip-worktree user.nix

nix build .#darwinConfigurations."$(hostname -s)".system
sudo ./result/sw/bin/darwin-rebuild switch --flake .

# git user config via GitHub (requires gh auth login first)
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  GH_ID=$(gh api user --jq '.id')
  GH_LOGIN=$(gh api user --jq '.login')
  git config --global user.name "$GH_LOGIN"
  git config --global user.email "${GH_ID}+${GH_LOGIN}@users.noreply.github.com"
fi

# Night Shift (21:00-7:00, temp 85)
brew tap smudge/smudge
brew trust smudge/smudge
brew install smudge/smudge/nightlight
nightlight temp 85 && nightlight schedule 21:00 7:00

# agy (Google Antigravity CLI) — not available via nix/brew
if ! command -v agy &>/dev/null; then
  curl -fsSL https://antigravity.google/cli/install.sh | bash
  agy install --skip-path
fi
