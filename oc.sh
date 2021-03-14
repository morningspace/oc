#!/bin/bash

# MIT License
# 
# Copyright (c) 2021 MorningSpace
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#
# Enhanced OpenShift Client: run oc securely and efficiently
# Author: https://github.com/morningspace
#
function oc {
  __oc_username=''
  __oc_password=''
  __oc_server=''
  __oc_credential_key=''
  __oc_positional=()

  if [[ $1 == login && $2 != -h && $2 != --help ]]; then

    while [[ $# -gt 0 ]]; do
      case "$1" in
      -s|--server)
        if [[ $1 =~ .*=.* ]]; then __oc_server="${1#*=}"; shift; else __oc_server="$2"; shift; shift; fi ;;
      -u|--username)
        if [[ $1 =~ .*=.* ]]; then __oc_username="${1#*=}"; shift; else __oc_username="$2"; shift; shift; fi ;;
      -p|--password)
        if [[ $1 =~ .*=.* ]]; then __oc_password="${1#*=}"; shift; else __oc_password="$2"; shift; shift; fi ;;
      -c|--credential-key)
        if [[ $1 =~ .*=.* ]]; then __oc_credential_key="${1#*=}"; shift; else __oc_credential_key="$2"; shift; shift; fi ;;
      *)
        __oc_positional+=("$1"); shift ;;
      esac
    done

    if [[ -z $__oc_credential_key ]]; then
      __oc_credential_key=`echo $__oc_server | sed -n 's@^https*://@@p'`
      __oc_credential_key="${__oc_credential_key//./-}"
      __oc_credential_key="${__oc_credential_key//:/-}"
    fi

    if [[ -n $__oc_credential_key && -z $__oc_username && -z $__oc_password ]]; then
      echo "Read login credential from secret store..."
      if gopass find $__oc_credential_key 2>/dev/null 1>&2; then
        __oc_server="$(gopass show -o "$__oc_credential_key" server 2>/dev/null)"
        __oc_username="$(gopass show -o "$__oc_credential_key" username 2>/dev/null)"
        __oc_password="$(gopass show -o "$__oc_credential_key" password 2>/dev/null)"
        
        [[ -z $__oc_server ]] && echo "error: server not found in secret store." && return -1
        [[ -z $__oc_username ]] && echo "error: username not found in secret store." && return -1
        [[ -z $__oc_password ]] && echo "error: password not found in secret store." && return -1

        echo "Login credential loaded successfully."
      else
        echo "error: server key '$__oc_credential_key' not found in secret store." && return -1
      fi

      command oc ${__oc_positional[@]} -s $__oc_server -u $__oc_username -p $__oc_password

    else
      [[ -z $__oc_server ]] && echo "error: server not specified." && return -1
      [[ -z $__oc_username ]] && echo "error: username not specified." && return -1
      [[ -z $__oc_password ]] && echo "error: password not specified." && return -1

      if command oc ${__oc_positional[@]} -s $__oc_server -u $__oc_username -p $__oc_password; then
        echo "Save login credential into secret store..."
        echo "$__oc_server"   | gopass insert -f "$__oc_credential_key" server || return -1
        echo "$__oc_username" | gopass insert -f "$__oc_credential_key" username || return -1
        echo "$__oc_password" | gopass insert -f "$__oc_credential_key" password || return -1

        echo "Login credential saved successfully."
      fi
    fi
  else
    command oc $@
  fi
}
