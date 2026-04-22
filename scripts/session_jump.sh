#!/usr/bin/env bash

set -euo pipefail

saved_dir="$HOME/.local/share/tmux/resurrect/saved"
resurrect_dir_config="$(tmux show-option -gv @resurrect-dir 2>/dev/null || echo 'NOT_SET')"
if [ "$resurrect_dir_config" != "NOT_SET" ]; then
	saved_dir="$resurrect_dir_config/saved"
fi

session_list="$(tmux list-sessions -F '#{session_name}' | while read -r s; do
	if [ -e "$saved_dir/$s.resurrect" ]; then
		printf '󱂬 %s\n' "$s"
	else
		printf '  %s\n' "$s"
	fi
done | fzf --reverse --info=right --no-preview --prompt 'jump to session: ' | sed 's/^[󱂬 ]*//')" || exit 0

[ -n "$session_list" ] && tmux switch-client -t "$session_list"
