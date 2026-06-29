#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Enable Touch ID for sudo before brew bundle runs
echo "auth sufficient pam_tid.so" | sudo tee /etc/pam.d/sudo_local > /dev/null

# Install Homebrew if not present
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Add Homebrew to PATH (Apple Silicon: /opt/homebrew, Intel: /usr/local)
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
brew bundle --file="$DOTFILES/.Brewfile" --verbose

# Verify cask apps actually exist; reinstall if brew thinks installed but app is missing
mapfile -t _casks < <(grep '^cask' "$DOTFILES/.Brewfile" | sed 's/cask "\(.*\)"/\1/')
mapfile -t _reinstall < <(brew info --cask --json=v2 "${_casks[@]}" 2>/dev/null | python3 -c "
import json,sys,os,subprocess

def pkgutil_installed(ids):
  all_pkgs=None
  for i in (ids if isinstance(ids,list) else [ids]):
    if '*' in i:
      if all_pkgs is None:
        all_pkgs=subprocess.run(['pkgutil','--pkgs'],capture_output=True,text=True).stdout
      if any(l.startswith(i.replace('*','')) for l in all_pkgs.splitlines()): return True
    elif subprocess.run(['pkgutil','--pkg-info',i],capture_output=True).returncode==0: return True
  return False

for cask in json.load(sys.stdin)['casks']:
  name=cask['token']; arts=cask.get('artifacts',[])
  app_path=next(('/Applications/'+a['app'][0] for a in arts if isinstance(a,dict) and 'app' in a),None)
  if app_path:
    if not os.path.exists(app_path): print(name)
    continue
  for a in arts:
    if not isinstance(a,dict): continue
    for u in a.get('uninstall',[]):
      if isinstance(u,dict) and 'pkgutil' in u:
        if not pkgutil_installed(u['pkgutil']): print(name)
        break
    else: continue
    break
")
for _cask in "${_reinstall[@]}"; do
  brew reinstall --cask "$_cask"
done

# Install Nix if not present
if ! command -v nix &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Symlinks (absolute source paths required)
link() { mkdir -p "$(dirname "$2")" && ln -sfn "$DOTFILES/$1" "$2"; }
link .tmux.conf ~/.tmux.conf
link .vimrc ~/.vimrc
link .zshrc ~/.zshrc
link .config/karabiner/karabiner.json ~/.config/karabiner/karabiner.json
link .config/karabiner/assets/complex_modifications ~/.config/karabiner/assets/complex_modifications
link .zsh/.p10k.zsh ~/.p10k.zsh

# Personalize user.nix and stage it so nix can read it from git index
cat > "$DOTFILES/user.nix" <<EOF
{ user = "$(whoami)"; host = "$(hostname -s)"; }
EOF
git -C "$DOTFILES" add --sparse user.nix

# nix-darwin manages sudo_local; remove the manually written file before activation
sudo rm -f /etc/pam.d/sudo_local

nix build "path:$DOTFILES#darwinConfigurations.$(hostname -s).system"
sudo ./result/sw/bin/darwin-rebuild switch --flake "path:$DOTFILES#$(hostname -s)"

git -C "$DOTFILES" update-index --skip-worktree user.nix

# Refresh PATH to include nix-managed binaries installed by darwin-rebuild
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"

# Set fish as default shell (nix-darwin doesn't manage this on macOS without uid)
FISH=/run/current-system/sw/bin/fish
[[ "$(dscl . -read /Users/"$USER" UserShell | awk '{print $2}')" != "$FISH" ]] && chsh -s "$FISH"

# git user config via GitHub
gh auth status &>/dev/null 2>&1 || gh auth login
GH_ID=$(gh api user --jq '.id')
GH_LOGIN=$(gh api user --jq '.login')
git config --file "$HOME/.gitconfig" user.name "$GH_LOGIN"
git config --file "$HOME/.gitconfig" user.email "${GH_ID}+${GH_LOGIN}@users.noreply.github.com"

# Night Shift (21:00-7:00, temp 85)
brew tap smudge/smudge
brew trust smudge/smudge
brew install smudge/smudge/nightlight
nightlight temp 85 && nightlight schedule 21:00 7:00

# agy (Google Antigravity CLI) — not available via nix/brew
if ! command -v agy &>/dev/null; then
  curl -fsSL https://antigravity.google/cli/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
  agy install --skip-path
fi
