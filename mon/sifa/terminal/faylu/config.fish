# Default fish configuration.
# Uncomment and modify the options below to customize your shell.

# ---------------------------------------------------------------------------
# Environment variables
# ---------------------------------------------------------------------------

# Set the default editor.
# set -gx EDITOR nvim
# set -gx VISUAL nvim

# Add custom directories to PATH.
# fish_add_path ~/.local/bin
# fish_add_path ~/bin

# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------

# fish ships with several built-in prompts. Run `fish_config` to preview them.
# set -g fish_greeting ""

# ---------------------------------------------------------------------------
# Aliases and abbreviations
# ---------------------------------------------------------------------------

# Abbreviations expand as you type (preferred over aliases in fish).
# abbr -a g git
# abbr -a ga 'git add'
# abbr -a gc 'git commit'
# abbr -a gp 'git push'
# abbr -a ll 'ls -l'
# abbr -a la 'ls -la'

# Traditional aliases are functions under the hood.
# alias cat 'bat --paging=never'

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

# Example: create a directory and cd into it.
# function mkcd
#     mkdir -p $argv[1]
#     cd $argv[1]
# end

# ---------------------------------------------------------------------------
# Key bindings
# ---------------------------------------------------------------------------

# fish uses emacs-style bindings by default. To use vi-style bindings:
# fish_vi_key_bindings

# ---------------------------------------------------------------------------
# Colors and theme
# ---------------------------------------------------------------------------

# Customize syntax highlighting colors.
# set -g fish_color_normal normal
# set -g fish_color_command blue
# set -g fish_color_param cyan
# set -g fish_color_redirection magenta
# set -g fish_color_comment brblack
# set -g fish_color_error red
# set -g fish_color_quote green
# set -g fish_color_operator yellow
# set -g fish_color_end normal
# set -g fish_color_autosuggestion brblack
# set -g fish_color_selection white --bold --background=brblack
# set -g fish_color_search_match bryellow --background=brblack

# ---------------------------------------------------------------------------
# Completion and history
# ---------------------------------------------------------------------------

# Limit history file size.
# set -g fish_history_max 100000

# ---------------------------------------------------------------------------
# Conditional settings (only run in interactive shells)
# ---------------------------------------------------------------------------

if status is-interactive
    # Commands to run in interactive sessions only.
    # Example: start a key agent or fetch system info.
end
