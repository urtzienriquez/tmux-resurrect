#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"

set -euo pipefail

resurrect_dir="$HOME/.local/share/tmux/resurrect"
resurrect_dir_config="$(tmux show-option -gv @resurrect-dir 2>/dev/null || echo 'NOT_SET')"
if [ "$resurrect_dir_config" != "NOT_SET" ]; then
	resurrect_dir="$resurrect_dir_config"
fi

saved_dir="$resurrect_dir/saved"
active_sessions="$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)"

session_list=""
shopt -s nullglob
for file in "$saved_dir"/*.resurrect; do
	session="$(basename "$file" .resurrect)"
	if printf '%s\n' "$active_sessions" | grep -Fxq "$session"; then
		session_list+=$'󰄴 '
		session_list+="$session"
	else
		session_list+=$'  '
		session_list+="$session"
	fi
	session_list+=$'\n'
done
shopt -u nullglob

[ -z "$session_list" ] && exit 0

selected="$(printf '%s' "$session_list" | fzf --info=right --reverse --no-preview --multi --prompt='Restore session(s): ' --bind 'tab:toggle+up' | sed 's/^[󰄴 ]*//')" || exit 0
[ -z "$selected" ] && exit 0

for session in $selected; do
	file="$saved_dir/$session.resurrect"
	[ -f "$file" ] || { echo "No saved session: $session"; continue; }

	if tmux has-session -t "$session" 2>/dev/null; then
		tmux display-message "Session '$session' is already active, switching to it..."
		continue
	fi

	cp "$file" "$resurrect_dir/last"
	tmux new-session -ds "$session"
	tmux list-windows -t "$session" -F '#{window_index}' | while read -r win; do
		tmux kill-window -t "${session}:${win}"
	done
	tmux run-shell -b "$CURRENT_DIR/restore.sh"
	sleep 0.3
done

last_session="$(printf '%s\n' "$selected" | sed -n '$p')"
[ -n "$last_session" ] && tmux switch-client -t "$last_session"
