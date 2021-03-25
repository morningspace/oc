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

# Enhanced OpenShift CLI: Using oc more securely and efficiently
# The original OpenShift CLI: https://github.com/openshift/oc/

function __oc_login_prompt {
  echo -n "$2"
  [[ -n $3 ]] && echo -n " [$3]"
  echo -n ": "

  local arg_value
  read -r ${@:4} arg_value
  [[ $4 == -s ]] && echo
  eval "$1=${arg_value:-$3}"
}

function __oc_login_gen_ctx_alias {
  local ctx_alias=`echo $1 | sed -n 's@^https*://@@p'`
  ctx_alias="${ctx_alias:-$1}"
  ctx_alias="${ctx_alias//./-}"
  ctx_alias="${ctx_alias//:/-}"
  ctx_alias="${ctx_alias//\//-}"
  echo "$ctx_alias"
}

function __oc_update_ctx_prompt {
  local ctx="$(__oc_login_gen_ctx_alias $1)"
  local ctx_alias="$(gopass show -o ".map/$ctx" 2>/dev/null)"
  ctx_alias=${ctx_alias:-$1}
  echo $ctx_alias
}

__oc_help_context_alias="  -c, --context-alias: Context alias as the shorthand of full context name"
__oc_help_head="An Enhanced Version of OpenShift Client

This is not a replacement of the original OpenShift Client, but a shell on top of it which 
requires the original client to be installed at first. For more information, please check: 
https://github.com/morningspace/oc/.

---------------------------------------------------------------------------------------------
Below is the original help information of OpenShift Client
---------------------------------------------------------------------------------------------
"

function oc {
  __oc_server=''
  __oc_username=''
  __oc_password=''
  __oc_token=''
  __oc_context_alias=''
  __oc_help=0

  if [[ $# == 0 ]]; then
    echo "$__oc_help_head"; command oc; return
  fi

  # Parse arguments
  __oc_positional=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help|help) __oc_help=1; shift ;;
      *)  __oc_positional+=("$1"); shift ;;
    esac
  done
  set -- ${__oc_positional[@]}

  # Preflight check
  local dependency
  for dependency in "oc|the original OpenShift CLI" gopass; do
    if ! command ${dependency%|*} -h >/dev/null 2>&1; then
      echo "error: This program needs ${dependency#*|} to be installed. You must install it first."
      return -1
    fi
  done

  # Display help information
  if [[ $__oc_help == 1 ]]; then
    if [[ $1 == login ]]; then
      command oc $@ -h | sed -E "s/^Options:/Options:|$__oc_help_context_alias/g" | tr '|' '\n'
    else
      command oc $@ -h
    fi
  elif [[ $1 == login ]]; then
    # Detect oc login withouth -h/--help
    # Parse arguments
    __oc_positional=()
    while [[ $# -gt 0 ]]; do
      local arg_name=""
      local arg_value=""
      case "$1" in
        -s|--server|-s=*|--server=*) arg_name="__oc_server" ;;
        -u|--username|-u=*|--username=*) arg_name="__oc_username";;
        -p|--password|-p=*|--password=*) arg_name="__oc_password" ;;
        --token|--token=*) arg_name="__oc_token" ;;
        -c|--context-alias|-c=*|--context-alias=*) arg_name="__oc_context_alias" ;;
        *) arg_name="" ;;
      esac

      if [[ -n $arg_name ]]; then
        if [[ $1 =~ .*=.* ]]; then
          arg_value="${1#*=}"
          __oc_positional+=($1)
          shift
        else
          arg_value="$2"
          __oc_positional+=($1) && shift
          [[ -n $1 ]] && __oc_positional+=($1) && shift
        fi
        eval "$arg_name=$arg_value"
      else
        __oc_positional+=("$1")
        shift
      fi
    done

    # Login using context from secret store
    if [[ -n $__oc_context_alias && -z $__oc_server && -z $__oc_username && -z $__oc_password && -z $__oc_token ]]; then
      local ctx
      local ctxs=($(gopass find $__oc_context_alias 2>/dev/null))
      # Has context(s)
      if [[ -n ${ctxs[@]} ]]; then
        # Has multiple contexts
        if [[ ${#ctxs[@]} != 1 ]]; then
          # Use fzf
          if command -v fzf >/dev/null 2>&1; then
            __oc_context_alias="$(for ctx in "${ctxs[@]}"; do echo $ctx; done | fzf)"
          else
            # Use select
            select ctx in "${ctxs[@]}"; do
              [[ ' '${ctxs[@]}' ' =~ ' '$ctx' ' ]] && __oc_context_alias="$ctx" && break
            done
          fi
          [[ -z $__oc_context_alias ]] && echo "error: Context not found in secret store." && return -1
        fi

        echo "Read context '$__oc_context_alias' from secret store..."

        __oc_server="$(gopass show -o "$__oc_context_alias" server 2>/dev/null)"
        __oc_username="$(gopass show -o "$__oc_context_alias" username 2>/dev/null)"
        __oc_password="$(gopass show -o "$__oc_context_alias" password 2>/dev/null)"
        
        [[ -z $__oc_server ]]   && echo "error: Server not found in secret store."   && return -1
        [[ -z $__oc_username ]] && echo "error: Username not found in secret store." && return -1
        [[ -z $__oc_password ]] && echo "error: Password not found in secret store." && return -1

        echo "Context loaded successfully."
      else
        # Has no context
        echo "error: Context '$__oc_context_alias' not found in secret store." && return -1
      fi

      command oc ${__oc_positional[@]}
    else
      # Login then save context to secret store
      [[ -z $__oc_server ]] && __oc_server="${__oc_positional[@]:1}"
      [[ -z $__oc_server ]] && __oc_login_prompt "__oc_server" "Server" "https://localhost:8443"

      # Do not save context if token specified
      if [[ -n $__oc_token ]]; then
        command oc ${__oc_positional[@]}
      else
        [[ -z $__oc_username ]] && __oc_login_prompt "__oc_username" "Username" "kubeadmin"
        [[ -z $__oc_password ]] && __oc_login_prompt "__oc_password" "Password" "" -s
        [[ -z $__oc_password ]] && echo "error: You must specify a password." && return -1
        [[ -z $__oc_context_alias ]] && __oc_login_prompt "__oc_context_alias" "Context alias" ""

        if command oc ${__oc_positional[@]} && [[ -n $current-context ]]; then
          echo "Save context '$__oc_context_alias' into secret store..."

          echo "$__oc_server"   | gopass insert -f "$__oc_context_alias" server || return -1
          echo "$__oc_username" | gopass insert -f "$__oc_context_alias" username || return -1
          echo "$__oc_password" | gopass insert -f "$__oc_context_alias" password || return -1

          # Save the mapping of the encoded full context name and the context alias
          local ctx="$(__oc_login_gen_ctx_alias $(command oc config current-context))"
          echo "$__oc_context_alias" | gopass insert -f ".map/$ctx" || return -1

          echo "Context saved successfully."
        fi
      fi
    fi
  else
    # Other oc commands
    command oc $@
  fi
}

# Register custom context prompt function for kube-ps1
# See: https://github.com/jonmosco/kube-ps1/
KUBE_PS1_CLUSTER_FUNCTION=__oc_update_ctx_prompt
