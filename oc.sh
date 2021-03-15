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
# The original OpenShift Client: https://github.com/openshift/oc/
# TODO:
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

function __oc_login_gen_ctx_key {
  local ctx_key=`echo $1 | sed -n 's@^https*://@@p'`
  ctx_key="${ctx_key//./-}"
  ctx_key="${ctx_key//:/-}"
  echo "$ctx_key"
}

function oc {
  __oc_server=''
  __oc_username=''
  __oc_password=''
  __oc_token=''
  __oc_context_key=''
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
        -c|--context-key|-c=*|--context-key=*) arg_name="__oc_context_key" ;;
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

    # Login using context from secret store
    if [[ -n $__oc_context_key && -z $__oc_server && -z $__oc_username && -z $__oc_password && -z $__oc_token ]]; then
      local ctx
      local ctxs=($(gopass find $__oc_context_key 2>/dev/null))
      # Has context(s)
      if [[ -n ${ctxs[@]} ]]; then
        # Has multiple contexts
        if [[ ${#ctxs[@]} != 1 ]]; then
          # Use fzf
          if command -v fzf >/dev/null 2>&1; then
            __oc_context_key="$(for ctx in "${ctxs[@]}"; do echo $ctx; done | fzf)"
          else
            # Use select
            select ctx in "${ctxs[@]}"; do
              [[ ' '${ctxs[@]}' ' =~ ' '$ctx' ' ]] && __oc_context_key="$ctx" && break
            done
          fi
          [[ -z $__oc_context_key ]] && echo "error: Context not found in secret store." && return -1
        fi

        echo "Read context '$__oc_context_key' from secret store..."

        __oc_server="$(gopass show -o "$__oc_context_key" server 2>/dev/null)"
        __oc_username="$(gopass show -o "$__oc_context_key" username 2>/dev/null)"
        __oc_password="$(gopass show -o "$__oc_context_key" password 2>/dev/null)"
        
        [[ -z $__oc_server ]]   && echo "error: Server not found in secret store."   && return -1
        [[ -z $__oc_username ]] && echo "error: Username not found in secret store." && return -1
        [[ -z $__oc_password ]] && echo "error: Password not found in secret store." && return -1

        echo "Context loaded successfully."
      else
        # Has no context
        echo "error: Context '$__oc_context_key' not found in secret store." && return -1
      fi

      command oc ${__oc_positional[@]} -s $__oc_server -u $__oc_username -p $__oc_password
    else
      # Login then save context to secret store

      [[ -z $__oc_server ]] && __oc_server="${__oc_positional[2]}" && unset "__oc_positional[2]"
      [[ -z $__oc_server ]] && __oc_login_prompt "__oc_server" "Server" "https://localhost:8443"

      # Do not save context if token specified
      if [[ -n $__oc_token ]]; then
        command oc ${__oc_positional[@]} -s $__oc_server --token $__oc_token
      else
        [[ -z $__oc_username ]] && __oc_login_prompt "__oc_username" "Username" "kubeadmin"
        [[ -z $__oc_password ]] && __oc_login_prompt "__oc_password" "Password" "" -s
        [[ -z $__oc_password ]] && echo "error: You must specify a password." && return -1
        [[ -z $__oc_context_key ]] && __oc_login_prompt "__oc_context_key" "Context key" "$(__oc_login_gen_ctx_key $__oc_server)"

        if command oc ${__oc_positional[@]} -s $__oc_server -u $__oc_username -p $__oc_password; then
          echo "Save context '$__oc_context_key' into secret store..."

          echo "$__oc_server"   | gopass insert -f "$__oc_context_key" server || return -1
          echo "$__oc_username" | gopass insert -f "$__oc_context_key" username || return -1
          echo "$__oc_password" | gopass insert -f "$__oc_context_key" password || return -1

          echo "Context saved successfully."
        fi
      fi
    fi
  else
    # Other oc commands
    command oc $@
  fi
}
