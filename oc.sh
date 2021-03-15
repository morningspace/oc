#!/bin/bash

# Copyright 2021 MorningSpace
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Enhanced OpenShift Client: Run oc more securely and efficiently
# TODO:
# - support server w/o -s
# - command prompt
# - help

function __oc_login_prompt {
  echo -n "$2"
  [[ -n $3 ]] && echo -n " [$3]"
  echo -n ": "

  local arg_value
  read -r ${@:4} arg_value
  eval "$1=${arg_value:-$3}"
}

function __oc_login_gen_cred_key {
  local cred_key=`echo $1 | sed -n 's@^https*://@@p'`
  cred_key="${cred_key//./-}"
  cred_key="${cred_key//:/-}"
  echo "$cred_key"
}

function oc {
  __oc_server=''
  __oc_username=''
  __oc_password=''
  __oc_token=''
  __oc_credential_key=''
  __oc_positional=()

  # Preflight check
  local dependency
  for dependency in "oc|the original OpenShift CLI" gopass; do
    if ! command ${dependency%|*} -h >/dev/null 2>&1; then
      echo "error: This program needs ${dependency#*|} to be installed. You must install it first."
      return -1
    fi
  done

  # Detect oc login withouth -h/--help
  if [[ $1 == login && $2 != -h && $2 != --help ]]; then

    # Parse arguments
    while [[ $# -gt 0 ]]; do
      local arg_name=""
      local arg_value=""
      case "$1" in
        -s|--server|-s=*|--server=*) arg_name="__oc_server" ;;
        -u|--username|-u=*|--username=*) arg_name="__oc_username";;
        -p|--password|-p=*|--password=*) arg_name="__oc_password" ;;
        --token|--token=*) arg_name="__oc_token" ;;
        -c|--credential-key|-c=*|--credential-key=*) arg_name="__oc_credential_key" ;;
        *) arg_name="" ;;
      esac

      if [[ -n $arg_name ]]; then
        if [[ $1 =~ .*=.* ]]; then
          arg_value="${1#*=}"
          shift
        else
          arg_value="$2"
          shift; shift
        fi
        eval "$arg_name=$arg_value"
      else
        __oc_positional+=("$1")
        shift
      fi
    done

    # Login using credential from secret store
    if [[ -n $__oc_credential_key && -z $__oc_server && -z $__oc_username && -z $__oc_password && -z $__oc_token ]]; then
      local cred
      local creds=($(gopass find $__oc_credential_key 2>/dev/null))
      # Has credential(s)
      if [[ -n ${creds[@]} ]]; then
        # Has multiple credentials
        if [[ ${#creds[@]} != 1 ]]; then
          # Use fzf
          if command -v fzf >/dev/null 2>&1; then
            __oc_credential_key="$(for cred in "${creds[@]}"; do echo $cred; done | fzf)"
          else
            # Use select
            select cred in "${creds[@]}"; do
              [[ ' '${creds[@]}' ' =~ ' '$cred' ' ]] && __oc_credential_key="$cred" && break
            done
          fi
          [[ -z $__oc_credential_key ]] && echo "error: Credential key not found in secret store." && return -1
        fi

        echo "Read login credential '$__oc_credential_key' from secret store..."

        __oc_server="$(gopass show -o "$__oc_credential_key" server 2>/dev/null)"
        __oc_username="$(gopass show -o "$__oc_credential_key" username 2>/dev/null)"
        __oc_password="$(gopass show -o "$__oc_credential_key" password 2>/dev/null)"
        
        [[ -z $__oc_server ]]   && echo "error: Server not found in secret store."   && return -1
        [[ -z $__oc_username ]] && echo "error: Username not found in secret store." && return -1
        [[ -z $__oc_password ]] && echo "error: Password not found in secret store." && return -1

        echo "Login credential loaded successfully."
      else
        # Has no credential
        echo "error: Credential key '$__oc_credential_key' not found in secret store." && return -1
      fi

      command oc ${__oc_positional[@]} -s $__oc_server -u $__oc_username -p $__oc_password
    else
      # Login then save credential to secret store

      [[ -z $__oc_server ]] && __oc_login_prompt "__oc_server" "Server" "https://localhost:8443"

      # Do not save credential if token specified
      if [[ -n $__oc_token ]]; then
        command oc ${__oc_positional[@]} -s $__oc_server --token $__oc_token
      else
        [[ -z $__oc_username ]] && __oc_login_prompt "__oc_username" "Username" "kubeadmin"
        [[ -z $__oc_password ]] && __oc_login_prompt "__oc_password" "Password" "" -s
        [[ -z $__oc_password ]] && echo "error: You must specify a password." && return -1
        [[ -z $__oc_credential_key ]] && __oc_login_prompt "__oc_credential_key" "Credential key" "$(__oc_login_gen_cred_key $__oc_server)"

        if command oc ${__oc_positional[@]} -s $__oc_server -u $__oc_username -p $__oc_password; then
          echo "Save login credential '$__oc_credential_key' into secret store..."

          echo "$__oc_server"   | gopass insert -f "$__oc_credential_key" server || return -1
          echo "$__oc_username" | gopass insert -f "$__oc_credential_key" username || return -1
          echo "$__oc_password" | gopass insert -f "$__oc_credential_key" password || return -1

          echo "Login credential saved successfully."
        fi
      fi
    fi
  else
    # Other oc commands
    command oc $@
  fi
}
