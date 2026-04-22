# Custom key bindings

The default key bindings are:

- `prefix + Ctrl-s` - save
- `prefix + Ctrl-r` - restore

To change these, add to `.tmux.conf`:

    set -g @resurrect-save 'S'
    set -g @resurrect-restore 'R'

The plugin also ships session-manager helper scripts. They default to:

    S / l / X / g

You can override them with tmux options if needed.

To disable the built-in bindings entirely:

    set -g @resurrect-enable-default-bindings off
    set -g @resurrect-enable-session-manager-bindings off
