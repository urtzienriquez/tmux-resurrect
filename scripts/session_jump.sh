#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"

set -euo pipefail

saved_dir="$(resurrect_dir)/saved"

session_list="$(tmux list-sessions -F '#{session_name}' | while read -r s; do
	if [ -e "$saved_dir/$s.resurrect" ]; then
		printf '󱂬 %s\n' "$s"
	else
		printf '  %s\n' "$s"
	fi
done | fzf --reverse --info=right --no-preview --prompt 'jump to session: ' | sed 's/^[󱂬 ]*//')" || exit 0

[ -n "$session_list" ] && tmux switch-client -t "$session_list"
