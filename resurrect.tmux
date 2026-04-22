#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/scripts/variables.sh"
source "$CURRENT_DIR/scripts/helpers.sh"

set_save_bindings() {
	local key_bindings=$(get_tmux_option "$save_option" "$default_save_key")
	local key
	for key in $key_bindings; do
		tmux bind-key "$key" run-shell "$CURRENT_DIR/scripts/save.sh"
	done
}

set_restore_bindings() {
	local key_bindings=$(get_tmux_option "$restore_option" "$default_restore_key")
	local key
	for key in $key_bindings; do
		tmux bind-key "$key" run-shell "$CURRENT_DIR/scripts/restore.sh"
	done
}

set_default_strategies() {
	tmux set-option -gq "${restore_process_strategy_option}irb" "default_strategy"
	tmux set-option -gq "${restore_process_strategy_option}mosh-client" "default_strategy"
}

default_bindings_enabled() {
	[ "$(get_tmux_option "$enable_default_bindings_option" "$default_enable_default_bindings")" = "on" ]
}

session_manager_bindings_enabled() {
	[ "$(get_tmux_option "$enable_session_manager_bindings_option" "$default_enable_session_manager_bindings")" = "on" ]
}

set_session_manager_bindings() {
	local key

	key="$(get_tmux_option "$session_save_key_option" "")"
	if [ -n "$key" ]; then
		tmux bind-key "$key" confirm-before -p "Save session #{session_name}? (y/n)" "run-shell 'bash $CURRENT_DIR/scripts/session_save.sh #{session_name}'"
	fi

	key="$(get_tmux_option "$session_restore_key_option" "")"
	if [ -n "$key" ]; then
		tmux bind-key "$key" display-popup -E "bash $CURRENT_DIR/scripts/session_restore.sh"
	fi

	key="$(get_tmux_option "$session_kill_key_option" "")"
	if [ -n "$key" ]; then
		tmux bind-key "$key" display-popup -E "bash $CURRENT_DIR/scripts/session_kill.sh"
	fi

	key="$(get_tmux_option "$session_jump_key_option" "")"
	if [ -n "$key" ]; then
		tmux bind-key "$key" display-popup -E "bash $CURRENT_DIR/scripts/session_jump.sh"
	fi
}

set_script_path_options() {
	tmux set-option -gq "$save_path_option" "$CURRENT_DIR/scripts/save.sh"
	tmux set-option -gq "$restore_path_option" "$CURRENT_DIR/scripts/restore.sh"
	tmux set-option -gq "$session_save_path_option" "$CURRENT_DIR/scripts/session_save.sh"
	tmux set-option -gq "$session_restore_path_option" "$CURRENT_DIR/scripts/session_restore.sh"
	tmux set-option -gq "$session_kill_path_option" "$CURRENT_DIR/scripts/session_kill.sh"
	tmux set-option -gq "$session_jump_path_option" "$CURRENT_DIR/scripts/session_jump.sh"
}

main() {
	if default_bindings_enabled; then
		set_save_bindings
		set_restore_bindings
	fi
	set_default_strategies
	if session_manager_bindings_enabled; then
		set_session_manager_bindings
	fi
	set_script_path_options
}
main
