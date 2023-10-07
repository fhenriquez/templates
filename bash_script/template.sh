#!/usr/bin/env bash
#####################################################################
# Script Name:
# Authors:
# Date:
# Description:
#
#                                                                   #
#####################################################################

# Required binaries:
# - getopt
#

# Notes:
#
#
__version__="0.1.0"
__author__=""
__email__=""

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)"


# Color Codes
# DESC: Initialize color variables
# ARGS: None
function echo_color_init(){

    Color_Off='\033[0m'       # Text Reset
    NC='\e[m'                 # Color Reset

    # Regular Colors
    Black='\033[0;30m'        # Black
    Red='\033[0;31m'          # Red
    Green='\033[0;32m'        # Green
    Yellow='\033[0;33m'       # Yellow
    Blue='\033[0;34m'         # Blue
    Purple='\033[0;35m'       # Purple
    Cyan='\033[0;36m'         # Cyan
    White='\033[0;37m'        # White

    # Bold
    BBlack='\033[1;30m'       # Black
    BRed='\033[1;31m'         # Red
    BGreen='\033[1;32m'       # Green
    BYellow='\033[1;33m'      # Yellow
    BBlue='\033[1;34m'        # Blue
    BPurple='\033[1;35m'      # Purple
    BCyan='\033[1;36m'        # Cyan
    BWhite='\033[1;37m'       # White

    # High Intensity
    IBlack='\033[0;90m'       # Black
    IRed='\033[0;91m'         # Red
    IGreen='\033[0;92m'       # Green
    IYellow='\033[0;93m'      # Yellow
    IBlue='\033[0;94m'        # Blue
    IPurple='\033[0;95m'      # Purple
    ICyan='\033[0;96m'        # Cyan
    IWhite='\033[0;97m'       # White

}


# Setting up logging
exec 3>&2 # logging stream (file descriptor 3) defaults to STDERR
verbosity=3 # default to show warnings
silent_lvl=0
crt_lvl=1
err_lvl=2
wrn_lvl=3
inf_lvl=4
dbg_lvl=5
bash_dbg_lvl=6

notify() { log $silent_lvl "${Cyan}NOTE${Color_Off}: $1"; } # Always prints
critical() { log $crt_lvl "${IRed}CRITICAL:${Color_Off} $1"; }
error() { log $err_lvl "${Red}ERROR:${Color_Off} $1"; }
warn() { log $wrn_lvl "${Yellow}WARNING:${Color_Off} $1"; }
info() { log $inf_lvl "${Blue}INFO:${Color_Off} $1"; } # "info" is already a command
debug() { log $dbg_lvl "${Purple}DEBUG:${Color_Off} $1"; }

log() {
    if [ "${verbosity}" -ge "${1}" ]; then
        datestring=$(date +'%Y-%m-%d %H:%M:%S')
        # Expand escaped characters, wrap at 70 chars, indent wrapped lines
        echo -e "$datestring - __${FUNCNAME[2]}__  - $2" >&3 #| fold -w70 -s | sed '2~1s/^/  /' >&3
    fi
}


logger() {
    if [ -n "${LOG_FILE}" ]
    then
        echo -e "$1" >> "${log_file}"
        #echo -e "$1" >> "${LOG_FILE/.log/}"_"$(date +%d%b%Y)".log
    fi
}


# DESC: What happens when ctrl-c is pressed
# ARGS: None
# Trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    info "Trapped CTRL-C signal, terminating script"
    logger "\n================== $(date +'%Y-%m-%d %H:%M:%S'): Run Interrupted  ==================\n"
    rm -f ${TEMP_FILE}
    exit 2
}

# DESC: Usage help
# ARGS: None
usage(){
	echo -e "\
	\rUsage: $0 -r <required>
    \rDescription:  Only the finest of descriptions go here.

	\rrequired arguments:
	\r-r, --required <required_parameter>\t This is a required parameter.

	\roptional arguments:
	\r-h, --help\t\t Show this help message and exit.
    \r-l, --log <file>\t Log file.
	\r-r, --required\t\t Argument that is required..
	\r-v, --verbose\t\t Verbosity.
    \r             \t\t -v info
    \r             \t\t -vv debug
    \r             \t\t -vv bash debug
	"

    return 0
}

# DESC: Parse arguments
# ARGS: main args
function parse_args(){

    local short_opts='h,l:,r:,v'
    local long_opts='help,log:,required:,verbose'

    # set -x # remove comment to troubleshoot

    # -use ! and PIPESTATUS to get exit code with errexit set
    # -temporarily store output to be able to check for errors
    # -activate quoting/enhanced mode (e.g. by writing out “--options”)
    # -pass arguments only via   -- "$@"   to separate them correctly
    ! PARSED=$(getopt --options=${short_opts} --longoptions=${long_opts} --name "$0" -- "$@")
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        # e.g. return value is 1
        #  then getopt has complained about wrong arguments to stdout
        debug "getopt has complained about wrong arguments"
        exit 2
    fi
    # read getopt’s output this way to handle the quoting right:
    eval set -- "$PARSED"

    if [[ "${PARSED}" == " --" ]]
    then
        debug "No arguments were passed"
        usage
        exit 1
    fi

    # Getting positional args
    if [[ "${pos_arguments}" == "true" ]]; then
        OLD_IFS=$IFS
        POSITIONAL_ARGS=${PARSED#*"--"}
        IFS=' ' read -r -a positional_args <<< "${POSITIONAL_ARGS}"
        IFS=$OLD_IFS
    fi

    # extract options and their arguments into variables.
    while true ; do
        case "$1" in
           -h | --help )
                # Display usage.
                usage
                exit 1;
                ;;
            -r | --required)
                required_var="$2"
                shift 2
                ;;
            -l | --log)
                LOG_FILE="$2"
                log_file="${LOG_FILE/.log/}"_"$(date +%d%b%Y)".log
                shift 2
                ;;
             -v | --verbose)
                (( verbosity = verbosity + 1 ))
                if [ $verbosity -eq $bash_dbg_lvl ]
                then
                    debug="true"
                fi
                shift
                ;;
             -- )
                shift
                break ;;
            * )
                usage
                exit 3
        esac
    done

    return 0
}

# DESC: main
# ARGS: None
function main(){

    # Any default values go here
    debug="false"
    verbose="false"
    pos_arguments="true"
    # pos_arguments="false"

    echo_color_init
    parse_args "$@"

    debug "
    out_file:        \t ${outfile}
    "

    # Getting positional arguments
    if [[ "${pos_arguments}" == "true" ]]; then
        OLD_IFS=$IFS
        IFS=' ' read -r -a pos_args <<< "${POSITIONAL_ARGS[@]}"
        IFS=${OLD_IFS}
    fi

    # Run in debug mode, if set
    if [ "${debug}" == "true" ]; then
        set -o noclobber
        set -o errexit          # Exit on most errors (see the manual)
        set -o errtrace         # Make sure any error trap is inherited
        set -o nounset          # Disallow expansion of unset variables
        set -o pipefail         # Use last non-zero exit code in a pipeline
        set -o xtrace           # Trace the execution of the script (debug)
    fi

    # Validating required variables.
    #if [ -z "${required_var:-}" ]
    #then
    #    usage
    #    exit 3
    #fi

    debug "Starting script"

    info "This is an info log message"

    # Main

    declare -a result

    # Positional parameters are validated here.
    # if not need you can remove
    if [[ "${pos_arguments}" == "true" ]]; then
        pos_arg_count=0
        len=${#pos_args[@]}
        if [[ ${len} == 0 ]]
        then
            debug "No positional argument passed if required."
            usage
            exit 1
        else
            while [ $pos_arg_count -lt $len ];
            do
                debug "Working with positional arg:: ${pos_args[$pos_arg_count]}"
                result+=$(echo "${pos_args[$pos_arg_count]}" | tr -d "'")
                result+="\n"

                # Need to increase count, to exit loop
                pos_arg_count=$((${pos_arg_count}+1))
            done
        fi
    else
        debug "No position arguments to work with"
        results+=($(echo "$@"))
    fi

    echo -e ${result[@]}
    return 0
}

# make it rain
main "$@"
debug "Script is complete"
logger "this is a test"
exit 0
