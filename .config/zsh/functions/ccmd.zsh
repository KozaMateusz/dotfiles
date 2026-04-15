function ccmd_stop_spinner() {
	emulate -L zsh

	if [[ -n "${CCMD_SPINNER_PID:-}" ]]; then
		kill "$CCMD_SPINNER_PID" >/dev/null 2>&1 || true
		wait "$CCMD_SPINNER_PID" 2>/dev/null || true
		CCMD_SPINNER_PID=""
		printf '\r\033[K' >&2
	fi
}

function ccmd_start_spinner() {
	emulate -L zsh

	local message="$1"

	(
		local frames='|/-\'
		local i=0
		while true; do
			printf '\r[%c] %s' "${frames:i++%${#frames}:1}" "$message" >&2
			sleep 0.1
		done
	) &

	CCMD_SPINNER_PID=$!
}

function ccmd_prompt_for_command() {
	emulate -L zsh
	setopt local_options errexit nounset pipefail

	local request="$1"
	local previous_command="${2:-}"
	local alternative_note="${3:-}"
	local failure_note="${4:-}"
	local prompt

	prompt=$(
		cat <<EOF
You convert natural-language requests into a single Bash command for the current directory.

Return JSON only, matching the provided schema.

Rules:
- Output exactly one shell command in the "command" field.
- Keep it short and practical.
- Prefer standard Unix tools.
- Do not use markdown or code fences.
- Do not ask follow-up questions.
- Assume the user will review the command before running it.
- If the request is underspecified, make the most reasonable default choice.

User request: $request
EOF
	)

	if [[ -n "$previous_command" ]]; then
		prompt+=$'\n'"Previous command: $previous_command"
		prompt+=$'\n'"Produce a different command from the previous one."
	fi

	if [[ -n "$alternative_note" ]]; then
		prompt+=$'\n'"User feedback for the alternative: $alternative_note"
	fi

	if [[ -n "$failure_note" ]]; then
		prompt+=$'\n'"The previous command failed when executed."
		prompt+=$'\n'"Execution failure details: $failure_note"
		prompt+=$'\n'"Fix the command based on that failure. Prefer using tools likely to already exist before suggesting installation."
	fi

	ccmd_start_spinner "Thinking..."

	if ! codex exec \
		--model gpt-5.2 \
		-c model_reasoning_effort='"none"' \
		-c model_reasoning_summary='"none"' \
		-c model_supports_reasoning_summaries=false \
		-c model_verbosity='"low"' \
		-c web_search='"disabled"' \
		--sandbox read-only \
		--skip-git-repo-check \
		--cd "$PWD" \
		--output-schema "$CCMD_SCHEMA_FILE" \
		--output-last-message "$CCMD_OUTPUT_FILE" \
		"$prompt" >/dev/null 2>"$CCMD_ERROR_FILE"; then
		ccmd_stop_spinner
		cat "$CCMD_ERROR_FILE" >&2
		return 1
	fi

	ccmd_stop_spinner
}

function ccmd_load_prompt_result() {
	emulate -L zsh

	CCMD_COMMAND="$(jq -r '.command' "$CCMD_OUTPUT_FILE")"
	CCMD_REASON="$(jq -r '.reason' "$CCMD_OUTPUT_FILE")"
}

function ccmd_extract_missing_command() {
	emulate -L zsh

	local error_text="$1"
	sed -nE 's/.*: ([^ :]+): command not found/\1/p' <<<"$error_text" | tail -n1
}

function ccmd_run_command() {
	emulate -L zsh
	setopt local_options pipefail

	local current_command="$1"
	local run_error_file run_error_text missing_command status

	run_error_file="$(mktemp)"

	if bash -lc "$current_command" 2>"$run_error_file"; then
		status=0
	else
		status=$?
	fi

	if [[ "$status" -eq 0 ]]; then
		cat "$run_error_file" >&2
		rm -f "$run_error_file"
		return 0
	fi

	run_error_text="$(cat "$run_error_file")"
	cat "$run_error_file" >&2
	rm -f "$run_error_file"

	if grep -qi 'command not found' <<<"$run_error_text"; then
		missing_command="$(ccmd_extract_missing_command "$run_error_text")"

		echo >&2
		if [[ -n "$missing_command" ]]; then
			echo "Command failed because \`$missing_command\` is not installed." >&2
		else
			echo "Command failed because a required executable is not installed." >&2
		fi
		echo "Trying to repair the command..." >&2

		ccmd_prompt_for_command "$CCMD_REQUEST" "$current_command" "" "$run_error_text"
		ccmd_load_prompt_result
		return 2
	fi

	return "$status"
}

function ccmd_choose_action() {
	emulate -L zsh

	if command -v gum >/dev/null 2>&1; then
		gum choose run alternative edit copy quit
	else
		printf "Choose [run/alternative/edit/copy/quit]: " >&2
		local action
		read -r action
		echo "$action"
	fi
}

function ccmd_read_alternative_feedback() {
	emulate -L zsh

	if command -v gum >/dev/null 2>&1; then
		gum input --placeholder "e.g. simpler, safer, recursive, with hidden files"
	else
		printf "How should the alternative differ? " >&2
		local feedback
		read -r feedback
		echo "$feedback"
	fi
}

function ccmd_edit_command() {
	emulate -L zsh

	local current_command="$1"

	if command -v gum >/dev/null 2>&1; then
		gum input --value "$current_command"
	else
		printf "Edit command [%s]: " "$current_command" >&2
		local edited_command
		read -r edited_command
		echo "${edited_command:-$current_command}"
	fi
}

function ccmd_copy_command() {
	emulate -L zsh

	local current_command="$1"

	if command -v wl-copy >/dev/null 2>&1; then
		printf '%s' "$current_command" | wl-copy
	elif command -v xclip >/dev/null 2>&1; then
		printf '%s' "$current_command" | xclip -selection clipboard
	elif command -v xsel >/dev/null 2>&1; then
		printf '%s' "$current_command" | xsel --clipboard --input
	elif command -v pbcopy >/dev/null 2>&1; then
		printf '%s' "$current_command" | pbcopy
	else
		echo "error: no clipboard tool found (tried wl-copy, xclip, xsel, pbcopy)" >&2
		return 1
	fi

	echo "Copied command to clipboard." >&2
}

function ccmd() {
	emulate -L zsh
	setopt local_options errexit nounset pipefail

	if (( $# < 1 )); then
		echo 'usage: ccmd "describe the command you want"'
		return 1
	fi

	if ! command -v codex >/dev/null 2>&1; then
		echo "error: codex is not installed or not on PATH"
		return 1
	fi

	if ! command -v jq >/dev/null 2>&1; then
		echo "error: jq is required"
		return 1
	fi

	local status action feedback
	CCMD_REQUEST="$*"
	CCMD_SCHEMA_FILE="$(mktemp)"
	CCMD_OUTPUT_FILE="$(mktemp)"
	CCMD_ERROR_FILE="$(mktemp)"
	CCMD_SPINNER_PID=""

	trap 'rm -f "$CCMD_SCHEMA_FILE" "$CCMD_OUTPUT_FILE" "$CCMD_ERROR_FILE"' RETURN

	cat >"$CCMD_SCHEMA_FILE" <<'EOF'
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "command": {
      "type": "string"
    },
    "reason": {
      "type": "string"
    }
  },
  "required": ["command", "reason"]
}
EOF

	ccmd_prompt_for_command "$CCMD_REQUEST"
	ccmd_load_prompt_result

	while true; do
		echo
		echo "Proposed command:"
		echo "  $CCMD_COMMAND"
		echo
		echo "Why:"
		echo "  $CCMD_REASON"
		echo

		action="$(ccmd_choose_action)"

		case "$action" in
			run)
				echo
				echo "Running:"
				echo "  $CCMD_COMMAND"
				echo
				if ccmd_run_command "$CCMD_COMMAND"; then
					status=0
				else
					status=$?
				fi

				if [[ "$status" -eq 0 ]]; then
					return 0
				fi
				if [[ "$status" -eq 2 ]]; then
					continue
				fi

				return "$status"
				;;
			alternative)
				feedback="$(ccmd_read_alternative_feedback)"
				ccmd_prompt_for_command "$CCMD_REQUEST" "$CCMD_COMMAND" "$feedback"
				ccmd_load_prompt_result
				;;
			edit)
				CCMD_COMMAND="$(ccmd_edit_command "$CCMD_COMMAND")"
				;;
			copy)
				ccmd_copy_command "$CCMD_COMMAND"
				;;
			quit)
				return 0
				;;
			*)
				echo "invalid choice: $action"
				;;
		esac
	done
}
