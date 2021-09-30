#!/bin/bash

# Execute a function on remote ssh host
# https://www.youtube.com/watch?v=uqHjc7hlqd0
# When writing function beware of local aliases
ssh_exec_func() {
    local ssh_opt=("-o" "StrictHostKeyChecking=no" "-o" "UserKnownHostsFile=/dev/null" "-o" "VisualHostKey=no" "-o" "ServerAliveInterval=7" "-o" "ServerAliveCountMax=4" "-o" "ControlPath=none" "-o" "ControlMaster=no" "-q")

    usage() {
        printf "%s\n" "Usage: ssh_exec_func [SSH_OPT ...] HOST -- FUNCTION_NAME [FUNCTION_ARG ...]"
    }

    [ "$#" -lt 3 ] && {
        usage 1>&2
        return 1
    }
    # Find `--` position
    i=1
    sep_pos=-1
    while [ "$i" -lt "$#" ]; do
        if [ "${!i}" = "--" ]; then
            sep_pos=$i
            break
        fi
        ((i++))
    done
    [ "$sep_pos" -eq "-1" ] && {
        usage 1>&2
        return 1
    }
    # Args as an array
    declare -a args=("$@")

    # SSH_OPT HOST
    declare -a ssh_extra_opt=("${args[@]:0:$sep_pos}")
    # FUNCTION_NAME
    declare -a func=("${args[@]:$sep_pos:1}")
    ((sep_pos++))
    # FUNCTION_ARGs
    declare -a func_args=("${args[@]:$sep_pos}")
    if [ "${#func_args}" = "0" ]; then
        ssh "${ssh_opt[@]}" "${ssh_extra_opt[@]}" "$(declare -f "${func[0]}";); \"${func[0]}\""
    else
        ssh "${ssh_opt[@]}" "${ssh_extra_opt[@]}" "$(declare -p func_args; declare -f "${func[0]}";); \"${func[0]}\" \"\${func_args[@]}\""
    fi
}
