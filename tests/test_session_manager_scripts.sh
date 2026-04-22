#!/usr/bin/env bash
set -euo pipefail

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLUGIN_DIR="$( cd "$CURRENT_DIR/.." && pwd )"

wait_for_session() {
	local socket="$1"
	local session="$2"
	local tries="${3:-50}"
	local delay="${4:-0.1}"
	local i
	for ((i=0; i<tries; i++)); do
		if tmux -L "$socket" has-session -t "$session" 2>/dev/null; then
			return 0
		fi
		sleep "$delay"
	done
	return 1
}

cleanup() {
	tmux -L "$SOCKET" kill-server >/dev/null 2>&1 || true
	rm -f "$HOME/resurrect-session-manager-test"
	rm -rf "$RESURRECT_ROOT" "$FAKEBIN"
}

assert_file_contains() {
	local file="$1"
	local pattern="$2"
	grep -q "$pattern" "$file"
}

assert_no_binding() {
	local socket="$1"
	local pattern="$2"
	! tmux -L "$socket" list-keys -T prefix | grep -q "$pattern"
}

SOCKET="resurrect-session-manager-$$"
RESURRECT_ROOT="$(mktemp -d)"
RESURRECT_DIR="$RESURRECT_ROOT/resurrect"
FAKEBIN="$(mktemp -d)"
trap cleanup EXIT

cat > "$FAKEBIN/fzf" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${FAKE_FZF_CHOICE:-}"
EOF
chmod +x "$FAKEBIN/fzf"

tmux -L "$SOCKET" -f /dev/null new-session -d -s red -c /tmp
tmux -L "$SOCKET" new-session -d -s blue -c /tmp
tmux -L "$SOCKET" set-option -g @resurrect-dir '~/resurrect-session-manager-test'
ln -s "$RESURRECT_DIR" "$HOME/resurrect-session-manager-test"
tmux -L "$SOCKET" set-option -g @resurrect-capture-pane-contents off
tmux -L "$SOCKET" set-option -g @resurrect-session-save S
tmux -L "$SOCKET" set-option -g @resurrect-session-restore l
tmux -L "$SOCKET" set-option -g @resurrect-session-kill X
tmux -L "$SOCKET" set-option -g @resurrect-session-jump g

tmux -L "$SOCKET" run-shell -b "$PLUGIN_DIR/resurrect.tmux"
sleep 0.2

tmux -L "$SOCKET" list-keys -T prefix | grep -q "session_save.sh"
tmux -L "$SOCKET" list-keys -T prefix | grep -q "session_restore.sh"
tmux -L "$SOCKET" list-keys -T prefix | grep -q "session_kill.sh"
tmux -L "$SOCKET" list-keys -T prefix | grep -q "session_jump.sh"

bash "$PLUGIN_DIR/scripts/session_save.sh" red

shopt -s nullglob
saved_files=("$RESURRECT_DIR/saved"/*.resurrect)
shopt -u nullglob
[ "${#saved_files[@]}" -eq 1 ]
assert_file_contains "${saved_files[0]}" $'^pane\tred\t'
! grep -q $'^pane\tblue\t' "${saved_files[0]}"

tmux -L "$SOCKET" kill-session -t red
wait_for_session "$SOCKET" blue

PATH="$FAKEBIN:$PATH" FAKE_FZF_CHOICE="red" bash "$PLUGIN_DIR/scripts/session_restore.sh"
wait_for_session "$SOCKET" red

PATH="$FAKEBIN:$PATH" FAKE_FZF_CHOICE="blue" bash "$PLUGIN_DIR/scripts/session_kill.sh"
sleep 0.2
! tmux -L "$SOCKET" has-session -t blue 2>/dev/null

TOGGLE_SOCKET="resurrect-toggle-$$"
tmux -L "$TOGGLE_SOCKET" -f /dev/null new-session -d -s toggle -c /tmp
tmux -L "$TOGGLE_SOCKET" set-option -g @resurrect-enable-default-bindings off
tmux -L "$TOGGLE_SOCKET" set-option -g @resurrect-enable-session-manager-bindings off
tmux -L "$TOGGLE_SOCKET" run-shell -b "$PLUGIN_DIR/resurrect.tmux"
sleep 0.2

assert_no_binding "$TOGGLE_SOCKET" 'C-s'
assert_no_binding "$TOGGLE_SOCKET" 'C-r'
assert_no_binding "$TOGGLE_SOCKET" 'session_save.sh'
assert_no_binding "$TOGGLE_SOCKET" 'session_restore.sh'
assert_no_binding "$TOGGLE_SOCKET" 'session_kill.sh'
assert_no_binding "$TOGGLE_SOCKET" 'session_jump.sh'
tmux -L "$TOGGLE_SOCKET" kill-server >/dev/null 2>&1 || true

bash -n "$PLUGIN_DIR/scripts/session_save.sh" "$PLUGIN_DIR/scripts/session_restore.sh" "$PLUGIN_DIR/scripts/session_kill.sh" "$PLUGIN_DIR/scripts/session_jump.sh"
