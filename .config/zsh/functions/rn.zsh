rn () {
	emulate -L zsh
	local pwd mount_dir remote_dir rel_path remote_pwd custom_cmd remote_cmd
	local -a additional_cmds

	pwd="$PWD"
	mount_dir="$HOME/Desktop/remote/rednode/"
	remote_dir="/home/mkoza/workspace/"
	rel_path="${pwd#"$mount_dir"}"
	remote_pwd="${remote_dir}${rel_path}"

	if ssh mkoza@rednode "[ ! -d \"$remote_pwd\" ]"
	then
		ssh -t mkoza@rednode "export TERM=xterm-256color; exec /usr/bin/zsh -l"
	elif (( $# == 0 ))
	then
		ssh -t mkoza@rednode "export TERM=xterm-256color; cd \"$remote_pwd\" && exec /usr/bin/zsh -l"
	else
		additional_cmds=(
			"export DL_DIR=/var/bitbake/downloads"
			"export SSTATE_DIR=/var/bitbake/sstate-cache"
			"export NETRC_FILE=~/.netrc"
			"export KAS_CONTAINER_IMAGE_DISTRO=debian-bookworm"
		)
		custom_cmd="$*"
		remote_cmd="$(printf "%s; " "${additional_cmds[@]}") $custom_cmd"
		ssh -t mkoza@rednode "export TERM=xterm-256color; cd \"$remote_pwd\" && $remote_cmd"
	fi
}
