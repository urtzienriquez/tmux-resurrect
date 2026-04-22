#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"

set -euo pipefail

session="${1:-}"
if [ -z "$session" ]; then
	session="$(tmux display-message -p '#{session_name}')"
fi

resurrect_dir="$(resurrect_dir)"

saved_dir="$resurrect_dir/saved"
mkdir -p "$saved_dir"

old_files=()
shopt -s nullglob
old_files=("$resurrect_dir"/tmux_resurrect_*.txt)
shopt -u nullglob

"$CURRENT_DIR/save.sh" quiet >/dev/null 2>&1

if [ ! -f "$resurrect_dir/last" ] && [ ! -L "$resurrect_dir/last" ]; then
	tmux display-message "Tmux resurrect file not found!"
	exit 1
fi

source_file=""
if [ -f "$resurrect_dir/last" ]; then
	source_file="$resurrect_dir/last"
elif [ -L "$resurrect_dir/last" ]; then
	source_file="$(readlink -f "$resurrect_dir/last" 2>/dev/null || true)"
	if [ ! -f "$source_file" ]; then
		tmux display-message "Cannot resolve resurrect 'last' file"
		exit 1
	fi
fi

awk -v sname="$session" '
  $1 == "state" { print; next }
  $2 == sname { print }
' "$source_file" > "$saved_dir/$session.resurrect"

for f in "${old_files[@]}"; do
	rm -f -- "$f" >/dev/null 2>&1 || true
done

original_display_time="$(tmux show-options -gv display-time)"
tmux set-option -g display-time 2000 \; display-message "Session '$session' saved!"
tmux set-option -g display-time "$original_display_time"
