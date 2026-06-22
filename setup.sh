#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

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

# Personalize user.nix (BSD sed: runs before nix provides GNU sed)
sed -i '' "s/username/$(whoami)/g" user.nix
sed -i '' "s/hostname/$(hostname -s)/g" user.nix
git update-index --skip-worktree user.nix

nix build .#darwinConfigurations."$(hostname -s)".system
sudo ./result/sw/bin/darwin-rebuild switch --flake .
