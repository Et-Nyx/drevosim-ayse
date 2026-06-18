# Fish shell user configuration
# https://fishshell.com/docs/current/index.html
#
# Put user-specific fish configuration entries here
# or in .fish files in conf.d/.
# Files in conf.d can be overridden by the system
# by files with the same name in /etc/fish/conf.d.
#
# This file is run by all fish instances.
# To include configuration only for login shells, use:
#   if status is-login
#       ...
#   end
# To include configuration only for interactive shells, use:
#   if status is-interactive
#       ...
#   end

# Because this wrapped fish is launched with --no-config, the default
# fish_greeting is not printed automatically. Re-enable it for interactive
# shells so the normal startup message is shown.
if status is-interactive
    fish_greeting
end
