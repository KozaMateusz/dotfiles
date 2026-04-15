fdo() {
  local dir
  local query="$1"

  dir=$(fd -t d . 2>/dev/null \
      | fzf --exact --query="$query" --select-1 --exit-0)

  if [ -n "$dir" ]; then
  cd "$dir" || return
  fi
}
