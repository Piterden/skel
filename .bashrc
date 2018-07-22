# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null
then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
else
    color_prompt=
fi

if [[ -f ~/.bash_colors ]]; then
    . ~/.bash_colors
fi

# if [ "$color_prompt" = yes ]; then
#     PS1="\[\033[38;5;42m\]\u\[$(tput sgr0)\]\[\033[38;5;156m\]@\[$(tput sgr0)\]\[\033[38;5;105m\]\h\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;169m\]\w\[$(tput sgr0)\]\[\033[38;5;9m\][\[$(tput sgr0)\]\[\033[38;5;196m\]\$?\[$(tput sgr0)\]\[\033[38;5;9m\]]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;5m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"
#     #PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
# else
#     PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
# fi

HOST_COLOR="\033[38;5;42m"

function __makeTerminalTitle() {
    local title=''

    local CURRENT_DIR="${PWD/#$HOME/\~}"

    if [ -n "${SSH_CONNECTION}" ]; then
        title+="`hostname`:${CURRENT_DIR} [`whoami`@`hostname -f`]"
    else
        title+="${CURRENT_DIR} [`whoami`]"
    fi

    echo -en '\033]2;'${title}'\007'
}

function __getMachineId() {
    if [ -f /etc/machine-id ]; then
        echo $((0x$(cat /etc/machine-id | head -c 15)))
    else
        echo $(( (${#HOSTNAME}+0x$(hostid))))
    fi
}

function __makePS1() {
    local EXIT="$?"

    if [ ! -n "${HOST_COLOR}" ]; then
        local H=$(__getMachineId)
        HOST_COLOR=$(tput setaf $((H%5 + 2))) # foreground
        #HOST_COLOR="\e[4$((H%5 + 2))m" # background
    fi

    PS1=''

    PS1+="${debian_chroot:+($debian_chroot)}"

    if [ ${USER} == root ]; then
        PS1+="\[${Red}\]" # root
    elif [ ${USER} != ${LOGNAME} ]; then
        PS1+="\[${Blue}\]" # normal user
    else
        PS1+="\[\033[38;5;42m\]" # normal user
        # PS1+="\[${Green}\]" # normal user
    fi
    PS1+="\u\[${Color_Off}\]"

    if [ -n "${SSH_CONNECTION}" ]; then
        PS1+="\[${BWhite}\]@"
        PS1+="\[${UWhite}${HOST_COLOR}\]\h\[${Color_Off}\]" # host displayed only if ssh connection
    fi

    PS1+=":\[${BYellow}\]\w" # working directory

    # background jobs
    local NO_JOBS=`jobs -p | wc -w`
    if [ ${NO_JOBS} != 0 ]; then
        PS1+=" \[${BGreen}\][j${NO_JOBS}]\[${Color_Off}\]"
    fi

    # screen sessions
    local SCREEN_PATHS="/var/run/screens/S-`whoami` /var/run/screen/S-`whoami` /var/run/uscreens/S-`whoami`"

    for screen_path in ${SCREEN_PATHS}; do
        if [ -d ${screen_path} ]; then
            SCREEN_JOBS=`ls ${screen_path} | wc -w`
            if [ ${SCREEN_JOBS} != 0 ]; then
                local current_screen="$(echo ${STY} | cut -d '.' -f 1)"
                if [ -n "${current_screen}" ]; then
                    current_screen=":${current_screen}"
                fi
                PS1+=" \[${BGreen}\][s${SCREEN_JOBS}${current_screen}]\[${Color_Off}\]"
            fi
            break
        fi
    done

    # git branch
    if [ -x "`which git 2>&1`" ]; then
        local branch="$(git name-rev --name-only HEAD 2>/dev/null)"

        if [ -n "${branch}" ]; then
            local git_status="$(git status --porcelain -b 2>/dev/null)"
            local letters="$( echo "${git_status}" | grep --regexp=' \w ' | sed -e 's/^\s\?\(\w\)\s.*$/\1/' )"
            local untracked="$( echo "${git_status}" | grep -F '?? ' | sed -e 's/^\?\(\?\)\s.*$/\1/' )"
            local status_line="$( echo -e "${letters}\n${untracked}" | sort | uniq | tr -d '[:space:]' )"
            PS1+=" \[${BBlue}\](${branch}"
            if [ -n "${status_line}" ]; then
                PS1+=" ${status_line}"
            fi
            PS1+=")\[${Color_Off}\]"
        fi
    fi

    # exit code
    if [ ${EXIT} != 0 ]; then
        PS1+=" \[${BRed}\][!${EXIT}]\[${Color_Off}\]"
    fi

    PS1+=" \[${BPurple}\]\\$\[${Color_Off}\] " # prompt

    __makeTerminalTitle
}

if [ "$color_prompt" = yes ]; then
    PROMPT_COMMAND=__makePS1
    PS2="\[${BPurple}\]>\[${Color_Off}\] " # continuation prompt
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

export LC_ALL="en_US.UTF-8"
export LANGUAGE="en_US"
export TERM="screen-256color"
export NVM_DIR=$HOME"/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

# Generating correct `.nanorc` file.
# You should to set right path starts from $HOME, ends with slash.
# Also it needs blank (or not) ~/.nanorc file
# nano_highlight_path=".nano/"
# if [ -f "$HOME"/.nanorc ]; then
#     > .nanorc
#     for syntax in $(ls "$nano_highlight_path"*.nanorc); do
#         echo "include \"$HOME/$syntax\"" >> .nanorc
#     done
# fi
