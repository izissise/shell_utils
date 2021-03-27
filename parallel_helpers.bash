#!/bin/bash

# Some helper functions to use with GNU parallel

# Create will-cite file so we don't get message
_parallel_create_willcite() {
    [ -e "$HOME/.parallel" ] || mkdir "$HOME/.parallel"
    [ -e "$HOME/.parallel/will-cite" ] || touch "$HOME/.parallel/will-cite"
}

# Automatically register functions that are
# commonly used with parallel helpers
_parallel_register_base_function() {
    __register_function "ssh_exec_func"
    __register_function "parallel_func_prepend_key"
}

# Register a function in bash environment
# https://www.gnu.org/software/parallel/parallel_tutorial.html#Transferring-environment-variables-and-functions
__register_function() {
    [ "$#" -ne 1 ] && {
        printf "%s\n" "Usage: __register_function FUNCTION_NAME"
        printf "%s\n" "You can then use parallel like this"
        printf "%s\n" "echo \"FUNCTION_NAME PARAM1 PARAM2\nFUNCTION_NAME PARAM3 PARAM4\" | parallel -j CONCURRENCY"
        return
    }
    export -f "${1?}"
}

__register_functions() {
    for f in "$@"; do
        __register_function "$f"
    done
}

# Prepend second argument (key) to each function output lines
parallel_func_prepend_key() {
    local func="$1"
    local key="$2"
    shift
    "$func" "$@" | sed -u "s/^/[$key] /"
}

# Override parallel command to setup environment
parallel() {
    _parallel_create_willcite
    _parallel_register_base_function
    command parallel "$@"
}

# Given a list of hosts execute a function on all of them using parallel
parallel_host_list_ssh_func() {
    [ "$#" -lt 2 ] && {
        printf "%s\n" "Usage: parallel_host_list_ssh_func HOST_LIST_FILE FUNCTION_NAME [PARALLEL_OPT ...]"
        return
    }
    local list="$1"
    local func_name="$2"
    local key_pre_func
    key_pre_func="$(echo "${PARALLEL_KEY_PRE_FUNC:-}" | sed '/^$/D;/.*/s/$/ /')"
    shift
    shift
    __register_function "$func_name"
    sed -E "s/(\$| )/ -- ${func_name}\1/;s/^/${key_pre_func}ssh_exec_func /" "$list" | parallel "$@"
}

# Same as `parallel_host_list_ssh_func` but prepend hostname on each output lines
parallel_host_list_ssh_func_prepend_key() {
    local PARALLEL_KEY_PRE_FUNC="parallel_func_prepend_key"
    parallel_host_list_ssh_func "$@"
}

# Given a list of entry execute a function on all row
parallel_list_exec_func() {
    [ "$#" -lt 2 ] && {
        printf "%s\n" "Usage: parallel_list_exec_func LIST_FILE FUNCTION_NAME [PARALLEL_OPT ...]"
        return
    }
    local list="$1"
    local func_name="$2"
    local key_pre_func
    key_pre_func="$(echo "${PARALLEL_KEY_PRE_FUNC:-}" | sed '/^$/D;/.*/s/$/ /')"
    shift
    shift
    __register_function "$func_name"
    sed "s/^/${key_pre_func}${func_name} /" "$list" | parallel "$@"
}

# Same as `parallel_list_exec_func` but prepend row on each output lines
parallel_list_exec_func_prepend_key() {
    local PARALLEL_KEY_PRE_FUNC="parallel_func_prepend_key"
    parallel_list_exec_func "$@"
}
