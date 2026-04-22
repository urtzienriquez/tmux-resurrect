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
	rm -rf "$RESURRECT_DIR" "$FAKEBIN"
}

assert_file_contains() {
	local file="$1"
	local pattern="$2"
	grep -q "$pattern" "$file"
}

SOCKET="resurrect-session-manager-$$"
RESURRECT_DIR="$(mktemp -d)"
FAKEBIN="$(mktemp -d)"
trap cleanup EXIT

cat > "$FAKEBIN/fzf" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${FAKE_FZF_CHOICE:-}"
EOF
chmod +x "$FAKEBIN/fzf"

tmux -L "$SOCKET" -f /dev/null new-session -d -s red -c /tmp
tmux -L "$SOCKET" new-session -d -s blue -c /tmp
tmux -L "$SOCKET" set-option -g @resurrect-dir "$RESURRECT_DIR"
tmux -L "$SOCKET" set-option -g @resurrect-capture-pane-contents off
tmux -L "$SOCKET" set-option -g @resurrect-grouped-sessions off

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

bash -n "$PLUGIN_DIR/scripts/session_save.sh" "$PLUGIN_DIR/scripts/session_restore.sh" "$PLUGIN_DIR/scripts/session_kill.sh" "$PLUGIN_DIR/scripts/session_jump.sh"
