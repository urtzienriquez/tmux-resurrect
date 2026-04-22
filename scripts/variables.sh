# key bindings
default_save_key="C-s"
save_option="@resurrect-save"
save_path_option="@resurrect-save-script-path"
enable_default_bindings_option="@resurrect-enable-default-bindings"
default_enable_default_bindings="on"

default_restore_key="C-r"
restore_option="@resurrect-restore"
restore_path_option="@resurrect-restore-script-path"

# custom session manager scripts
session_save_path_option="@resurrect-session-save-script-path"
session_restore_path_option="@resurrect-session-restore-script-path"
session_kill_path_option="@resurrect-session-kill-script-path"
session_jump_path_option="@resurrect-session-jump-script-path"
default_session_save_key="S"
default_session_restore_key="l"
default_session_kill_key="X"
default_session_jump_key="g"
session_save_key_option="@resurrect-session-save"
session_restore_key_option="@resurrect-session-restore"
session_kill_key_option="@resurrect-session-kill"
session_jump_key_option="@resurrect-session-jump"
enable_session_manager_bindings_option="@resurrect-enable-session-manager-bindings"
default_enable_session_manager_bindings="on"

# default processes that are restored
default_proc_list_option="@resurrect-default-processes"
default_proc_list='vi vim view nvim emacs man less more tail top htop irssi weechat mutt'

# User defined processes that are restored
#  'false' - nothing is restored
#  ':all:' - all processes are restored
#
# user defined list of programs that are restored:
#  'my_program foo another_program'
restore_processes_option="@resurrect-processes"
restore_processes=""

# Defines part of the user variable. Example usage:
#   set -g @resurrect-strategy-vim "session"
restore_process_strategy_option="@resurrect-strategy-"

inline_strategy_token="->"
inline_strategy_arguments_token="*"

save_command_strategy_option="@resurrect-save-command-strategy"
default_save_command_strategy="ps"

# Pane contents capture options.
# @resurrect-pane-contents-area option can be:
#   'visible' - capture only the visible pane area
#   'full'    - capture the full pane contents
pane_contents_option="@resurrect-capture-pane-contents"
pane_contents_area_option="@resurrect-pane-contents-area"
default_pane_contents_area="full"

# set to 'on' to ensure panes are never ever overwritten
overwrite_option="@resurrect-never-overwrite"

# Hooks are set via ${hook_prefix}${name}, i.e. "@resurrect-hook-post-save-all"
hook_prefix="@resurrect-hook-"

delete_backup_after_option="@resurrect-delete-backup-after"
default_delete_backup_after="30" # days
