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
  if [[ $# == 0 ]]; then
    # Display general help information
    echo "$__oc_help_head"
    command oc
  elif [[ $1 == login ]]; then
    # Customized oc login
    __oc_login ${@:2}
  else
    # Other oc commands
    command oc $@
  fi
}

function __oc_login {
  local __oc_server
  local __oc_username
  local __oc_password
  local __oc_token
  local __oc_context_alias
  local __oc_help
  local __oc_flags=()
  local __oc_positional=()
  local __oc_flag
  local __oc_value
  local __oc_hasvalue

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -s*|--server*)
        __oc_flag="server"
        __oc_hasvalue="y"
        ;;
      -u*|--username*)
        __oc_flag="username"
        __oc_hasvalue="y"
        ;;
      -p*|--password*)
        __oc_flag="password"
        __oc_hasvalue="y"
        ;;
      --token*)
        __oc_flag="token"
        __oc_hasvalue="y"
        ;;
      --certificate-authority*|--insecure-skip-tls-verify*)
        __oc_flag="*"
        __oc_hasvalue="y"
        ;;
      -h|--help)
        __oc_flag="help"
        __oc_hasvalue="n"
        ;;
      -c*|--context-alias*)
        __oc_flag="context_alias"
        __oc_hasvalue="y"
        ;;
      -*)
        __oc_flag="*"
        __oc_hasvalue="*"
        ;;
      *)
        __oc_flag="-"
        __oc_hasvalue="-"
        ;;
    esac

    # not a flag
    [[ $__oc_flag == "-" ]] && __oc_positional+=("$1") && shift && continue

    # a flag
    if [[ $__oc_hasvalue == "n" ]]; then
      __oc_value=1
      __oc_flags+=($1)
      shift
    elif [[ $__oc_hasvalue == "y" ]]; then
      if [[ $1 =~ = ]]; then
        __oc_value="${1#*=}"
        __oc_flags+=($1)
        shift
      elif [[ -n $2 ]]; then
        __oc_value="$2"
        __oc_flags+=($1 $2)
        shift; shift
      else
        __oc_value=""
        __oc_flags+=($1)
        shift
      fi
    else
      __oc_flags+=($1)
      shift
    fi

    [[ $__oc_flag != "*" ]] && eval "__oc_${__oc_flag}=${__oc_value}"
  done

  # Preflight check
  local dependency
  for dependency in "oc|the original OpenShift CLI" gopass; do
    if ! command ${dependency%|*} -h >/dev/null 2>&1; then
      echo "error: This program needs ${dependency#*|} to be installed. You must install it first."
      return 1
    fi
  done

  # Display oc login help information
  if [[ $__oc_help == 1 ]]; then
    command oc login ${__oc_positional[@]} ${__oc_flags[@]} | sed -E "s/^Options:/Options:|$__oc_help_context_alias/g" | tr '|' '\n'
    return
  fi

  local ctx
  if [[ -n $__oc_context_alias ]]; then
    # Login using context from secret store
    local ctx_arr=($(gopass find $__oc_context_alias 2>/dev/null))
    local ctx_num=${#ctx_arr[@]}

    if (( $ctx_num > 0 )); then
      # Context(s) found
      if (( $ctx_num > 1 )); then
        # Multiple contexts found
        if command -v fzf >/dev/null 2>&1; then
          # Use fzf
          __oc_context_alias="$(for ctx in "${ctx_arr[@]}"; do echo $ctx; done | fzf)"
        else
          # Use select
          select ctx in "${ctx_arr[@]}"; do
            [[ ' '${ctx_arr[@]}' ' =~ ' '$ctx' ' ]] && __oc_context_alias="$ctx" && break
          done
        fi
        [[ -z $__oc_context_alias ]] && echo "error: Context not found in secret store." && return 1
      else
        # One context found
        __oc_context_alias="${ctx_arr[@]}"
      fi

      echo "Read context '$__oc_context_alias' from secret store..."

      __oc_server="$(gopass show -o "$__oc_context_alias" server 2>/dev/null)"
      __oc_username="$(gopass show -o "$__oc_context_alias" username 2>/dev/null)"
      __oc_password="$(gopass show -o "$__oc_context_alias" password 2>/dev/null)"
      
      [[ -z $__oc_server   ]] && echo "error: Server not found in secret store."   && return 1
      [[ -z $__oc_username ]] && echo "error: Username not found in secret store." && return 1
      [[ -z $__oc_password ]] && echo "error: Password not found in secret store." && return 1

      echo "Context loaded successfully."

      command oc login $__oc_server -u $__oc_username -p $__oc_password
    else
      # No context found
      echo "error: Context '$__oc_context_alias' not found in secret store." && return 1
    fi
  else
    # Login then save context to secret store
    if [[ -n $__oc_token ]]; then
      # Do not save context if token specified
      command oc login ${__oc_positional[@]} ${__oc_flags[@]}
    else
      [[ -z $__oc_server ]] && __oc_server="${__oc_positional[@]}"
      [[ -z $__oc_server ]] && __oc_login_prompt "__oc_server" "Server" "https://localhost:8443"
      [[ -z $__oc_username ]] && __oc_login_prompt "__oc_username" "Username" "kubeadmin"
      [[ -z $__oc_password ]] && __oc_login_prompt "__oc_password" "Password" "" -s
      [[ -z $__oc_password ]] && echo "error: You must specify a password." && return 1
      [[ -z $__oc_context_alias ]] && __oc_login_prompt "__oc_context_alias" "Context alias" ""

      if command oc login ${__oc_positional[@]} ${__oc_flags[@]} && [[ -n $__oc_context_alias ]]; then
        echo "Save context '$__oc_context_alias' into secret store..."

        echo -n "$__oc_server"   | gopass insert -f "$__oc_context_alias" server   || return 1
        echo -n "$__oc_username" | gopass insert -f "$__oc_context_alias" username || return 1
        echo -n "$__oc_password" | gopass insert -f "$__oc_context_alias" password || return 1

        # Save the mapping of the encoded full context name and the context alias
        ctx="$(__oc_login_gen_ctx_alias $(command oc config current-context))"
        echo -n "$__oc_context_alias" | gopass insert -f ".map/$ctx" || return 1

        echo "Context saved successfully."
      fi
    fi
  fi
}

# Register custom context prompt function for kube-ps1
# See: https://github.com/jonmosco/kube-ps1/
KUBE_PS1_CLUSTER_FUNCTION=__oc_update_ctx_prompt
