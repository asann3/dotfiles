#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

read -rp "Keyboard type? [jp/us] (default: jp): " KEYBOARD
KEYBOARD=${KEYBOARD:-jp}

# Base packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential clang wl-clipboard

# ===== Japanese IME: IBus + Mozc =====
# IBus is more stable than fcitx5 under GNOME + Wayland
sudo apt install -y ibus ibus-mozc
im-config -n ibus

if [ "$KEYBOARD" = "us" ]; then
  # Remap Alt_L → Muhenkan, Alt_R → Henkan at kernel level (Wayland-safe)
  # "overload": tap alone sends the key, held with other keys acts as Alt
  # keyd is not in Ubuntu repos; build from source
  git clone --depth 1 https://github.com/rvaiya/keyd /tmp/keyd
  make -C /tmp/keyd && sudo make -C /tmp/keyd install
  rm -rf /tmp/keyd
  sudo mkdir -p /etc/keyd
  sudo tee /etc/keyd/default.conf > /dev/null << 'EOF'
[ids]
*

[main]
leftalt = overload(alt, muhenkan)
rightalt = overload(alt, henkan)
EOF
  sudo systemctl enable --now keyd

  MOZC_ENGINE="mozc-us"
  MOZC_LAYOUT="us"
else
  MOZC_ENGINE="mozc-jp"
  MOZC_LAYOUT="jp"
fi

# GNOME: use Mozc as sole input source
gsettings set org.gnome.desktop.input-sources sources "[('ibus', '${MOZC_ENGINE}')]"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[]"

# Mozc custom keymap: Henkan=IMEOn, Muhenkan=IMEOff (works for both JP and US via keyd)
# Encodes MS-IME keymap with overrides as protobuf into config1.db
python3 << 'PYEOF'
import urllib.request, os

url = "https://raw.githubusercontent.com/google/mozc/master/src/data/keymap/ms-ime.tsv"
with urllib.request.urlopen(url) as resp:
    lines = resp.read().decode('utf-8').splitlines(keepends=True)

new_lines = []
for line in lines:
    parts = line.strip().split('\t')
    if len(parts) == 3:
        status, key, command = parts
        if key == 'Henkan':
            new_lines.append(f'{status}\tHenkan\tIMEOn\n')
            continue
        elif key == 'Muhenkan':
            new_lines.append(f'{status}\tMuhenkan\tIMEOff\n')
            continue
    new_lines.append(line)

keymap_bytes = ''.join(new_lines).encode('utf-8')

def varint(n):
    out = []
    while n > 0x7f:
        out.append(0x80 | (n & 0x7f))
        n >>= 7
    out.append(n)
    return bytes(out)

# field 41 (session_keymap) = CUSTOM (0), field 42 (custom_keymap_table) = TSV
f41 = varint((41 << 3) | 0) + varint(0)
f42 = varint((42 << 3) | 2) + varint(len(keymap_bytes)) + keymap_bytes

os.makedirs(os.path.expanduser('~/.config/mozc'), exist_ok=True)
with open(os.path.expanduser('~/.config/mozc/config1.db'), 'wb') as f:
    f.write(f41 + f42)
print(f'config1.db written ({len(f41 + f42)} bytes)')
PYEOF

# Mozc: set keyboard layout (prevents layout resetting to US when Mozc is sole input)
mkdir -p ~/.config/mozc
cat > ~/.config/mozc/ibus_config.textproto << EOF
engines {
  name : "${MOZC_ENGINE}"
  longname : "Mozc"
  layout : "${MOZC_LAYOUT}"
  layout_variant : ""
  layout_option : ""
  rank : 80
}
active_on_launch: False
EOF
ibus write-cache

# ===== GNOME tools =====
sudo apt install -y gnome-shell-extension-manager gnome-tweaks

# ===== Nix =====
if ! command -v nix &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# ===== home-manager =====
cat > "$DOTFILES/user.nix" <<EOF
{ user = "$(whoami)"; host = "$(hostname -s)"; }
EOF
git -C "$DOTFILES" add --sparse user.nix
git -C "$DOTFILES" update-index --skip-worktree user.nix

nix run github:nix-community/home-manager/master -- switch --flake "path:$DOTFILES#$(whoami)@$(hostname -s)"

export PATH="$HOME/.nix-profile/bin:$PATH"

# Set fish as default shell
FISH_PATH="$(which fish)"
grep -qx "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells
sudo usermod -s "$FISH_PATH" "$USER"

# ===== git user config =====
gh auth status &>/dev/null 2>&1 || gh auth login
GH_ID=$(gh api user --jq '.id')
GH_LOGIN=$(gh api user --jq '.login')
git config --file "$HOME/.gitconfig" user.name "$GH_LOGIN"
git config --file "$HOME/.gitconfig" user.email "${GH_ID}+${GH_LOGIN}@users.noreply.github.com"

# ===== GNOME settings =====
# Night Light (blue light filter, 21:00-7:00)
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 21.0
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 7.0
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3500

# CapsLock → Ctrl
gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"

# Night Theme Switcher (installed via Nix)
gnome-extensions enable nightthemeswitcher@romainvigier.fr 2>/dev/null || \
  echo "Note: run 'gnome-extensions enable nightthemeswitcher@romainvigier.fr' after next login"

echo ""
echo "Done. Reboot to apply IBus and fish shell."
