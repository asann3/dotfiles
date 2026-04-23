sed -i '' "s/username/$(whoami)/g" user.nix
sed -i '' "s/hostname/$(hostname -s)/g" user.nix
git update-index --skip-worktree user.nix
nix build .#darwinConfigurations."$(hostname -s)".system
sudo ./result/sw/bin/darwin-rebuild switch --flake .
