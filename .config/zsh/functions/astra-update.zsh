function astra-update() {
	emulate -L zsh

	local synaimg_dir mode tag

	synaimg_dir="$PWD/SYNAIMG"
	mode="$1"

	tag="$(find "$synaimg_dir" -type f -name "*rootfs*" | head -n 1)"
	if [[ -z "$tag" ]]; then
		echo "No rootfs tag found"
		return 1
	fi
	tag="${tag%%.rootfs*}"

	case "$tag" in
		*261*)
			builtin cd /opt/usb-tool-sl261x-v2.3/ || return 1

			if [[ "$mode" == "bootloaders" ]]; then
				python usb_boot_tool.py --op run-acore \
					--sm "$synaimg_dir/sysmgr.subimg" \
					--bl "$synaimg_dir/bl.subimg" \
					--tzk "$synaimg_dir/tzk.subimg"
			else
				python usb_boot_tool.py --op emmc --img-dir "$synaimg_dir"
			fi
			;;

		*1680*)
			builtin cd /opt/usb-tool-astra-update-v1.0.5/ || return 1
			./bin/linux/x86_64/astra-update -f "$synaimg_dir"
			;;

		*)
			echo "Unknown platform: $tag"
			return 2
			;;
	esac
  
  cd -
}
