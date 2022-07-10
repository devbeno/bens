#!/bin/bash

# ---------------------------------------------------------
# Helper functions
# ---------------------------------------------------------

# True if command or file does exist
has() {
  if [ -e "$1" ]; then return 0; fi
  command -v $1 >/dev/null 2>&1 && { return 0; }
  return 1
}

# True if command or file doesn't exist
hasnt() {
  if [ -e "$1" ]; then return 1; fi
  command -v $1 >/dev/null 2>&1 && { return 1; }
  return 0
}

# True if variable is not empty
defined() {
  if [ -z "$1" ]; then return 1; fi  
  return 0
}

# True if variable is empty
undefined() {
  if [ -z "$1" ]; then return 0; fi
  return 1
}

# True if argument has error output
error() {
  local err="$($@ 2>&1 > /dev/null)"  
  if [ -z "$err" ]; then return 1; fi
  return 0
}

# Pretty messages
# echo_color black/on_red Warning message!
# echo_color prompt/yellow/on_purple This is a prompt
echo_color() {
  
  local black='\e[0;30m'  ublack='\e[4;30m'  on_black='\e[40m'  reset='\e[0m'
  local red='\e[0;31m'    ured='\e[4;31m'    on_red='\e[41m'    default='\e[0m'
  local green='\e[0;32m'  ugreen='\e[4;32m'  on_green='\e[42m'
  local yellow='\e[0;33m' uyellow='\e[4;33m' on_yellow='\e[43m'
  local blue='\e[0;34m'   ublue='\e[4;34m'   on_blue='\e[44m'
  local purple='\e[0;35m' upurple='\e[4;35m' on_purple='\e[45m'
  local cyan='\e[0;36m'   ucyan='\e[4;36m'   on_cyan='\e[46m'
  local white='\e[0;37m'  uwhite='\e[4;37m'  on_white='\e[47m'
  
  local format=""
  for color in $(echo "$1" | tr "/" "\n"); do  
    format="${format}${!color}"
  done
  local message="${@:2}"  
  
  printf "${format}${message}${reset}\n";
  
}

echo_line() {
  local color=$1 char=$2 line=""
  defined $1 || color="reset"
  defined $2 || char="⎯"
  for i in $(seq $(tput cols)); do
    line="${line}${char}"
  done
  echo_color $color $line
}

echo_env() {
  defined $1 || return
  local key="$1" val="${!1}" trim=$2
  if defined $trim; then
    val="$(echo $val | head -c $trim)[...]$(echo $val | tail -c $trim)"
  fi
  echo "$(echo_color white "${key}=")$(echo_color green "\"${val}\"")"
}

echo_env_example() {
  defined $1 || return
  defined $2 || return
  local key="$1" val="${2}"
  echo_line yellow
  echo "$(echo_color yellow "export") $(echo_color white "${key}=")$(echo_color green "\"${val}\"")"
  echo_line yellow
}


echo_main() {
  defined $1 || return
  echo
  echo_line blue
  echo "$(echo_color black/on_blue " ★ ") $(echo_color blue " ${@} ")"
  echo_line blue
}

echo_main_alt() {
  defined $1 || return
  echo
  echo
  echo "$(echo_color black/on_blue " ★ ") $(echo_color blue " ${@} ")"
  echo_line blue
}

echo_next() {
  defined $1 || return
  echo
  echo "$(echo_color black/on_green " ▶︎ ") $(echo_color green " ${@} ")"
}

echo_info() {
  defined $1 || return
  echo
  echo "$(echo_color black/on_yellow " ✔︎ ") $(echo_color yellow " ${@} ")"
}

echo_stop() {
  defined $1 || return
  echo
  echo "$(echo_color black/on_red " ✖︎ ") $(echo_color red " ${@} ")"
}

# If $answer is "y", then we don't bother with user input
ask() { 
  echo
  echo "$(echo_color black/on_yellow " ? ") $(echo_color yellow " ${@} ")"
  read -p " y/[n] " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
  if [ ! $? -ne 0 ]; then return 0; else return 1; fi
}

ask_input() { 
  echo
  echo -n "$(echo_color black/on_yellow " ? ") $(echo_color yellow " ${1}: ")"
}

# Echo the command before running it. 
# If 2 parameters, first one is remote, second is command to run on remote
# If 1 parameter, the command is run locally
echo_run() {
  defined $1 || return
  if defined $2; then
    echo "[${1}] ${2}"
    run "${1}" "${2}"
  else
    echo "$1"
    $1
  fi
}


# env DO_AUTH_TOKEN my-secret-token
# > attempts to load DO_AUTH_TOKEN from .env and environment
# > falls back on named file in CWD or /usr/local/env
# > falls back on my-secret-token as default value
env() {

  # Exit if no arguments passed
  [ -z "$1" ] && return 1

  # Load dotenv if available
  [ -e .env ] && dotenv="$(egrep -v '^#' .env | xargs)"
  [ -z "$dotenv" ] || export $dotenv

  # Set value from environment
  local var="${!1}"

  # If this is null, load from file
  if [ -z "$var" ]; then

    # Try to load filename as-is
    if [ -e "${1}" ]; then
      var="$(cat ${1})"

    # If that doesn't exist, try to load it under /usr/local/env/
    elif [ -e "/usr/local/env/${1}" ]; then
      var="$(cat /usr/local/env/${1})"

    # Default value from second parameter if nothing else
    else
      var="${2}"
    fi

  fi

  # Send back value
  echo "$var"

}

# Ask for input, using environment variable or file as suggested value
ask_env() {

  # Exit if no arguments passed
  [ -z "$1" ] && return 1

  # Load dotenv if available
  [ -e .env ] && dotenv="$(egrep -v '^#' .env | xargs)"
  [ -z "$dotenv" ] || export $dotenv

  # Set value from environment
  local var="${!1}"

  # If this is null, load from file
  if [ -z "$var" ]; then

    # Try to load filename as-is
    if [ -e "${1}" ]; then
      var="$(cat ${1})"

    # If that doesn't exist, try to load it under /usr/local/env/
    elif [ -e "/usr/local/env/${1}" ]; then
      var="$(cat /usr/local/env/${1})"

    # Default value from second parameter if nothing else
    else
      var="${2}"
    fi

  fi

  # Read input with suggestion
  if [ ! -z "$var" ]; then
    read -e -i "${var}" var
  else
    read var
  fi

  # Send back value
  echo "$var"

}

# Save env variable to /usr/local/env
set_env() {

  # Exit if no arguments passed
  [ -z "$1" ] && return 1

  local base="/usr/local/env"
  local file="${base}/${1}"
  local val="${!1}"

  # If this is null, load from file
  [ -z "$val" ] && return 1

  mkdir -p $base
  echo_next "Writing $file"
  echo "$val" | tee "$file"

}

# Append line to end of file if it doesn't exist
append() {
  if [ $# -lt 2 ] || [ ! -r "$2" ]; then
    echo 'Usage: append "line to append" /path/to/file'
  else
    grep -q "^$1" $2 || echo "$1" | tee --append $2
  fi
}

# Echos /dev/stdin or first argument if provided
input() {
  defined "$1" && echo "$1" && return 0
  test -p /dev/stdin && awk '{print}' /dev/stdin && return 0 || return 1
}

# Strip a string to only lowercase alphanumeric with hypen + underscore
slugify() {
  echo "$(input $1)" | tr -cd '[:alnum:]-.' | tr '[:upper:]' '[:lower:]' | tr '.' '_' | xargs
}

hyphenify() {
  echo "$(input $1)" | tr -cd '[:alnum:]_.' | tr '[:upper:]' '[:lower:]' | tr '.' '-' | xargs
}

node_from_fqdn() {
  echo "$(input $1)" | tr '.' ' ' | awk '{print $1}'
}

domain_from_fqdn() {
  echo "$(input $1)" | tr '.' ' ' | awk '{$1=""}1' | xargs | tr ' ' '.'
}

node_from_slug() {
  echo "$(input $1)" | tr '_' ' ' | awk '{print $1}'
}

domain_from_slug() {
  echo "$(input $1)" | tr '_' ' ' | awk '{$1=""}1' | xargs | tr ' ' '.'
}

args() {
  echo "$(input $1)" | tr ' ' '\n' | sort | uniq | xargs
}

rargs() {
  echo "$(input $1)" | tr ' ' '\n' | sort | uniq | tac | xargs
}

first() {
  echo "$(input $1)" | awk '{print $1}'
}

after_first() {
  echo "$(input $1)" | awk '{$1=""}1' | xargs
}

lines() {
  echo "$(input $1)" | tr ' ' "\n"
}

add() {
  x=10
  echo $((x + $1))
}

generate_password() {
  local length=25;
  defined $1 && length=$1 
  tr -cd '[:alnum:]' < /dev/urandom | fold -w$length | head -n 1
}

generate_key() {
  local key; key="/tmp/key-$(echo '('`date +"%s.%N"` ' * 1000000)/1' | bc)"
  ssh-keygen -b 4096 -t rsa -f $key -q -N ""
  cat $key | base64 | tr -d '\n'
  rm "${key}" "${key}.pub"
}


verify_esh() {

  # Install esh (if it isn't already)
  if hasnt esh; then
    
    echo_next "Installing esh..."
    
    # https://github.com/jirutka/esh/releases
    local version="0.3.1"
    curl -sL https://github.com/jirutka/esh/archive/v${version}/esh-${version}.tar.gz | tar -xz
    mv esh-${version} .esh
    if error "mv ./.esh/esh /usr/local/bin/esh"; then
      rm -rf ./.esh
      echo_stop "Missing permissions to move esh to /usr/local/bin"
      echo "chown that directory so your user can write to it."
      exit 1

    else
      rm -rf ./.esh
      echo "...ok!"
      echo
    fi

  fi
  
}

# Mark this as loaded
export HELPERS_LOADED=1
