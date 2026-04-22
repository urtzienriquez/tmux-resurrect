#!/usr/bin/env bash
set -euo pipefail

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLUGIN_DIR="$( cd "$CURRENT_DIR/.." && pwd )"
RESURRECT_DIR=""
SAVE_SOCKET=""
RESTORE_SOCKET=""

wait_for_file() {
	local file_path="$1"
	local tries="${2:-50}"
	local delay="${3:-0.1}"
	local i
	for ((i=0; i<tries; i++)); do
		[ -e "$file_path" ] && return 0
		sleep "$delay"
	done
	return 1
}

wait_for_session() {
	local socket="$1"
	local session_name="$2"
	local tries="${3:-50}"
	local delay="${4:-0.1}"
	local i
	for ((i=0; i<tries; i++)); do
		if tmux -L "$socket" has-session -t "$session_name" 2>/dev/null; then
			return 0
		fi
		sleep "$delay"
	done
	return 1
}

cleanup_socket() {
	local socket="$1"
	tmux -L "$socket" kill-server >/dev/null 2>&1 || true
}

cleanup_all() {
	[ -n "$SAVE_SOCKET" ] && cleanup_socket "$SAVE_SOCKET"
	[ -n "$RESTORE_SOCKET" ] && cleanup_socket "$RESTORE_SOCKET"
	[ -n "$RESURRECT_DIR" ] && rm -rf "$RESURRECT_DIR"
}

run_save_test() {
	local socket="$1"
	local resurrect_dir="$2"
	local grouped_sessions_state="$3"

	tmux -L "$socket" -f /dev/null new-session -d -s red -c /tmp
	tmux -L "$socket" set-option -g @resurrect-dir "$resurrect_dir"
	tmux -L "$socket" set-option -g @resurrect-capture-pane-contents off
	tmux -L "$socket" set-option -g @resurrect-grouped-sessions "$grouped_sessions_state"
	tmux -L "$socket" new-session -d -t red -s red-linked -c /tmp
	tmux -L "$socket" run-shell "$PLUGIN_DIR/scripts/save.sh quiet"

	wait_for_file "$resurrect_dir/last"
	local save_file
	save_file="$(readlink -f "$resurrect_dir/last")"

	if [ "$grouped_sessions_state" = "on" ]; then
		grep -q $'^grouped_session\tred-linked\tred\t' "$save_file"
		! grep -q $'^pane\tred-linked\t' "$save_file"
		! grep -q $'^window\tred-linked\t' "$save_file"
	else
		! grep -q $'^grouped_session\t' "$save_file"
		grep -q $'^pane\tred-linked\t' "$save_file"
		grep -q $'^window\tred-linked\t' "$save_file"
	fi

	cleanup_socket "$socket"
}

run_restore_test() {
	local socket="$1"
	local resurrect_dir="$2"

	local save_file
	save_file="$(readlink -f "$resurrect_dir/last")"
	printf 'grouped_session\tred-linked\tred\t:0\t:1\n' >> "$save_file"
	rm -f "$resurrect_dir/last"
	cp "$save_file" "$resurrect_dir/last"

	tmux -L "$socket" -f /dev/null new-session -d -s 0 -c /tmp
	tmux -L "$socket" set-option -g @resurrect-dir "$resurrect_dir"
	tmux -L "$socket" set-option -g @resurrect-capture-pane-contents off
	tmux -L "$socket" set-option -g @resurrect-grouped-sessions off
	tmux -L "$socket" run-shell "$PLUGIN_DIR/scripts/restore.sh"

	wait_for_session "$socket" red
	wait_for_session "$socket" red-linked
}

main() {
	RESURRECT_DIR="$(mktemp -d)"
	SAVE_SOCKET="resurrect-save-$$"
	RESTORE_SOCKET="resurrect-restore-$$"

	trap cleanup_all EXIT

	run_save_test "$SAVE_SOCKET" "$RESURRECT_DIR" on
	run_save_test "$SAVE_SOCKET" "$RESURRECT_DIR" off
	run_restore_test "$RESTORE_SOCKET" "$RESURRECT_DIR"
}

main
