#!/usr/bin/env bash


LOG_OUT="/dev/stdout"
ERR_OUT="/dev/stderr"


print_help() {
cat << EOF
Usage: $0 [OPTIONS]

Options:
  -u, --users         List system users and their home directories
  -p, --processes     List running processes sorted by PID
  -l, --log PATH      Redirect standard output to file at PATH
  -e, --errors PATH   Redirect stderr output to file at PATH
  -h, --help          Show this help message and exit
EOF
}

list_users() {
    if ! getent passwd 2>/dev/null | awk -F: '{print $1 " " $6}' | sort; then
        echo "Error: failed to retrieve users" >&2
    fi
}

list_processes() {
    if ! ps -eo pid,comm 2>/dev/null | sort -n; then
        echo "Error: failed to retrieve processes" >&2
    fi
}

ARGS=$(getopt -o upl:e:h --long users,processes,log:,errors:,help -n "$(basename "$0")" -- "$@")
if [ $? -ne 0 ]; then
    echo "Error parsing arguments" >&2
    exit 1
fi

eval set -- "$ARGS"

DO_USERS=false
DO_PROCESSES=false

while true; do
    case "$1" in
        -u|--users)
            DO_USERS=true
            shift
            ;;
        -p|--processes)
            DO_PROCESSES=true
            shift
            ;;
        -l|--log)
            PATH_TO_LOG="$2"
            if { [ -e "$PATH_TO_LOG" ] && [ -w "$PATH_TO_LOG" ]; } || \
               { [ ! -e "$PATH_TO_LOG" ] && [ -w "$(dirname "$PATH_TO_LOG")" ]; }; then
                LOG_OUT="$PATH_TO_LOG"
            else
                echo "Error: cannot write to log file $PATH_TO_LOG" >&2
                exit 1
            fi
            shift 2
            ;;
        -e|--errors)
            PATH_TO_ERR="$2"
            if { [ -e "$PATH_TO_ERR" ] && [ -w "$PATH_TO_ERR" ]; } || \
               { [ ! -e "$PATH_TO_ERR" ] && [ -w "$(dirname "$PATH_TO_ERR")" ]; }; then
                ERR_OUT="$PATH_TO_ERR"
            else
                echo "Error: cannot write to error file $PATH_TO_ERR" >&2
                exit 1
            fi
            shift 2
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done


exec 1>"$LOG_OUT"
exec 2>"$ERR_OUT"


if $DO_USERS; then
    list_users
fi

if $DO_PROCESSES; then
    list_processes
fi
