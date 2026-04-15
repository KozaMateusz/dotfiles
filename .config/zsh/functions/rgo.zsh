function rgo() {
	emulate -L zsh

	rg --vimgrep "$@" \
		| fzf --delimiter ':' \
			--bind "enter:execute(
				nvim +{2} {1}
			)"
}
