# Command history tweaks:
# - Append history instead of overwriting
#   when shell exits.
# - When using history substitution, do not
#   exec command immediately.
# - Do not save to history commands starting
#   with space.
# - Do not save duplicated commands.
shopt -s histappend
shopt -s histverify
export HISTCONTROL=ignoreboth

# Default command line prompt.
PROMPT_DIRTRIM=2
# Test if PS1 is set to the upstream default value, and if so overwrite it with our default.
# This allows users to override $PS1 by passing it to the invocation of bash as an environment variable
[[ "$PS1" == '\s-\v\$ ' ]] && PS1='\[\e[0;32m\]\w\[\e[0m\] \[\e[0;97m\]\$\[\e[0m\] '

# cl-andro prompt: shows ~ for home, ~/dir for subdirs, full path otherwise.
# Uses only bash builtins (cd, pwd -P) — no external commands.
# pwd -P resolves /data/data <-> /data/user/0 symlinks on Android.
# PROMPT_COMMAND runs after this file and overrides PS1 on every prompt.
# NOTE: the ~ in the replacement operand of ${var/pattern/replacement} MUST be
# escaped (\~) — otherwise bash applies tilde expansion to it and replaces the
# prefix with the literal $HOME path, defeating the whole purpose.
PROMPT_COMMAND='_cl_h=$(cd "$HOME" 2>/dev/null && pwd -P); _cl_p=$(pwd -P); _cl_p="${_cl_p/#$_cl_h/\~}"; PS1="\[\e[0;32m\]${_cl_p}\[\e[0m\] \[\e[0;97m\]\$\[\e[0m\] "'

# Handles nonexistent commands.
# If user has entered command which invokes non-available
# utility, command-not-found will give a package suggestions.
if [ -x "@TERMUX_PREFIX@/libexec/termux/command-not-found" ]; then
	command_not_found_handle() {
		"@TERMUX_PREFIX@"/libexec/termux/command-not-found "$1"
	}
fi

[ -r @TERMUX_PREFIX@/share/bash-completion/bash_completion ] && . @TERMUX_PREFIX@/share/bash-completion/bash_completion
# vim: set noet ft=bash tw=4 sw=4 ff=unix
