# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

DOTFILES_PATH=$HOME/dotfiles

source $DOTFILES_PATH/.zsh/plugins.zsh

export HOMEBREW_CASK_OPTS="--appdir=/Applications"
# To customize prompt, run `p10k configure` or edit ~/dotfiles/.zsh/.p10k.zsh.
[[ ! -f ~/dotfiles/.zsh/.p10k.zsh ]] || source ~/dotfiles/.zsh/.p10k.zsh
