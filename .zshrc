if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  fast-syntax-highlighting
)
source $ZSH/oh-my-zsh.sh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# this fixes a bug where omarchy defines functions that conflict with
# pre-existing aliases.
unalias ga
unalias gd

# from Omarchy
[[ $- != *i* ]] && return
[[ -f /usr/share/omarchy-zsh/shell/zoptions ]] && source /usr/share/omarchy-zsh/shell/zoptions
[[ -f /usr/share/omarchy-zsh/shell/all ]] && source /usr/share/omarchy-zsh/shell/all

# mine
export PATH="$HOME/.cargo/bin:$PATH"
if [ "$TMUX" = "" ]; then tmux; fi
setopt extended_glob

alias c=clear
alias ls="eza -h --group-directories-first --icons=auto"
alias pb="wl-copy"

for zsh_function_file in "$HOME/.config/zsh/functions"/*.zsh(.N); do
	source "$zsh_function_file"
done
