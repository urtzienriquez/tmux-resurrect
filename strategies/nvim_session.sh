#!/usr/bin/env bash

# "nvim session strategy"
#
# Restore nvim with Session.vim and/or Session.shada when present.
# Falls back to plain nvim if neither file exists.

ORIGINAL_COMMAND="$1"
DIRECTORY="$2"

nvim_session_file_exists() {
	[ -e "${DIRECTORY}/Session.vim" ]
}

nvim_shada_file_exists() {
	[ -e "${DIRECTORY}/Session.shada" ]
}

main() {
	if nvim_session_file_exists && nvim_shada_file_exists; then
		echo "nvim -i '${DIRECTORY}/Session.shada' -S '${DIRECTORY}/Session.vim'"
	elif nvim_session_file_exists; then
		echo "nvim -S"
	elif nvim_shada_file_exists; then
		echo "nvim -i '${DIRECTORY}/Session.shada'"
	else
		echo "$ORIGINAL_COMMAND"
	fi
}

main
