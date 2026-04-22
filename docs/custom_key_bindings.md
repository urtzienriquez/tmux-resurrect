# Custom key bindings

The default key bindings are:

- `prefix + Ctrl-s` - save
- `prefix + Ctrl-r` - restore

To change these, add to `.tmux.conf`:

    set -g @resurrect-save 'S'
    set -g @resurrect-restore 'R'

The plugin also ships session-manager helper scripts. Set these tmux options
before loading the plugin and it will bind them for you:

    set -g @resurrect-session-kill 'X'
    set -g @resurrect-session-restore 'l'
    set -g @resurrect-session-jump 'g'
    set -g @resurrect-session-save 'S'
