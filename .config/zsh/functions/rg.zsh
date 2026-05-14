function rg() {
  local args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -E)
        shift
        args+=(--glob "!$1")
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done
  command rg "${args[@]}"
}
