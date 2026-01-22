if status is-interactive
    and not set -q TMUX
    and test "$TERM_PROGRAM" != "vscode"

    set session_name "temp-"(date +%s)"-"%self

    # セッション作成時に destroy-unattached on (切断時に破棄) を設定して起動
    tmux new-session -s $session_name \; set-option destroy-unattached on
end

command -q kiro && string match -q "$TERM_PROGRAM" "kiro" and . (kiro --locate-shell-integration-path fish)

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /opt/homebrew/Caskroom/miniforge/base/bin/conda
    eval /opt/homebrew/Caskroom/miniforge/base/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/opt/homebrew/Caskroom/miniforge/base/etc/fish/conf.d/conda.fish"
        . "/opt/homebrew/Caskroom/miniforge/base/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/opt/homebrew/Caskroom/miniforge/base/bin" $PATH
    end
end
# <<< conda initialize <<<

alias brew-x86="arch -x86_64 /usr/local/bin/brew"
fish_add_path ~/bin/xelatex
# Added by Antigravity
fish_add_path ~/.antigravity/antigravity/bin
