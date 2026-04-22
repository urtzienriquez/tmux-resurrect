# Custom key bindings

The default key bindings are:

- `prefix + Ctrl-s` - save
- `prefix + Ctrl-r` - restore

To change these, add to `.tmux.conf`:

    set -g @resurrect-save 'S'
    set -g @resurrect-restore 'R'

The plugin also ships session-manager helper scripts. You can bind them with
the script paths exposed by tmux options:

    bind-key X display-popup -E "bash #{@resurrect-session-kill-script-path}"
    bind-key l display-popup -E "bash #{@resurrect-session-restore-script-path}"
    bind-key g display-popup -E "bash #{@resurrect-session-jump-script-path}"
    bind-key S confirm-before -p "Save session #{session_name}? (y/n)" "run-shell 'bash #{@resurrect-session-save-script-path} #{session_name}'"
