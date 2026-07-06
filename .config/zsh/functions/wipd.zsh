wipd() {
  printf '%s@%s:%s\n' "$USER" "$(hostname -i | awk '{print $1}')" "$PWD"
}
