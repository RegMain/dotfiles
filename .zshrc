eval "$(starship init zsh)"

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

autoload -Uz compinit
compinit
zstyle ':completion:*' menu select


export ZSH="$HOME/.oh-my-zsh"

plugins=(git alias-finder colored-man-pages command-not-found extract wd)

source $ZSH/oh-my-zsh.sh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=white'
ZSH_HIGHLIGHT_STYLES[alias]='fg=white'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=white'
ZSH_HIGHLIGHT_STYLES[function]='fg=white'
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

export EDITOR='micro'
export VISUAL='micro'
export XWAYLAND_NO_GLAMOR=1
export TERMINAL="alacritty"
### ALIASES

alias ls='eza --icons=always --group-directories-first'
alias ll='eza -lh --icons=always --group-directories-first'
alias la='eza -lah --icons=always --group-directories-first'

alias cat='bat --style=plain'

alias grep='grep --color=auto'

alias hx='helix'

mkcd() {
  if [ -n "$1" ]; then
    mkdir -p "$1" && cd "$1"
  else
    echo "Use: mkcd <path>"
  fi
}

alias ff='firefox'
alias neofetch='fastfetch'
alias poweruse='upower -i /org/freedesktop/UPower/devices/battery_LBAT | grep "energy-rate"'
alias bsd-games='echo "adventure, arithmetic, atc, battlestar, caesar, cribbage, dab, drop4, gofish, gomoku, hangman, klondike, robots, sail, snake, spirhunt, worm, wump"'
