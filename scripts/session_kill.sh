#!/usr/bin/env bash

set -euo pipefail

sessions="$(tmux list-sessions -F '#{session_name}' | fzf --info=right --reverse --multi --no-preview --prompt='Kill session(s): ' --bind 'tab:toggle+up')"
[ -z "$sessions" ] && exit 0

while IFS= read -r session; do
	tmux kill-session -t "$session"
done <<< "$sessions"
