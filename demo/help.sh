# Load enhanced oc
. ../oc.sh

# The demo cluster you want to access
DEMO_SERVER=
# The username used to access the cluster
DEMO_USER=
# The context alias for the demo cluster
DEMO_CONTEXT_ALIAS=
# The full alias name
DEMO_CONTEXT_FULL_ALIAS=
# The partial alias name
DEMO_CONTEXT_PART_ALIAS=

function tutorial::enhanced-oc-setup {
  if [[ -z $DEMO_SERVER || -z $DEMO_USER || -z $DEMO_CONTEXT_ALIAS || -z $DEMO_CONTEXT_FULL_ALIAS || -z $DEMO_CONTEXT_PART_ALIAS ]]; then
    echo '$DEMO_* environment variables should not be empty.'
    return 1
  fi
}

# Path to kube-ps1
DEMO_KUBE_PS1_PATH=~/.kube-ps1/kube-ps1.sh

function tutorial::custom-ps-setup {
  if [[ ! -f $DEMO_KUBE_PS1_PATH ]]; then
    echo 'kube-ps1 not found.'
    return 1
  fi

  # Load kube-ps1
  . $DEMO_KUBE_PS1_PATH

  # Setup kube-ps1
  KUBE_PS1_SYMBOL_USE_IMG=true

  # Export kube-ps1 variables and functions
  export PROMPT_COMMAND
  export KUBE_PS1_SHELL
  export KUBE_PS1_BINARY
  export KUBE_PS1_SYMBOL_ENABLE
  export KUBE_PS1_SYMBOL_DEFAULT
  export KUBE_PS1_SYMBOL_PADDING
  export KUBE_PS1_SYMBOL_USE_IMG
  export KUBE_PS1_NS_ENABLE
  export KUBE_PS1_CONTEXT_ENABLE
  export KUBE_PS1_PREFIX
  export KUBE_PS1_SEPARATOR
  export KUBE_PS1_DIVIDER
  export KUBE_PS1_SUFFIX
  export KUBE_PS1_SYMBOL_COLOR
  export KUBE_PS1_CTX_COLOR
  export KUBE_PS1_NS_COLOR
  export KUBE_PS1_BG_COLOR
  export KUBE_PS1_KUBECONFIG_CACHE
  export KUBE_PS1_DISABLE_PATH
  export KUBE_PS1_LAST_TIME
  export KUBE_PS1_CLUSTER_FUNCTION
  export KUBE_PS1_NAMESPACE_FUNCTION

  export -f __oc_update_ctx_prompt
  export -f __oc_login_gen_ctx_alias
  export -f _kube_ps1_color_fg
  export -f _kube_ps1_color_bg
  export -f _kube_ps1_binary_check
  export -f _kube_ps1_symbol
  export -f _kube_ps1_split
  export -f _kube_ps1_file_newer_than
  export -f _kube_ps1_update_cache
  export -f _kube_ps1_get_context
  export -f _kube_ps1_get_ns
  export -f _kube_ps1_get_context_ns
  export -f kube_ps1

  DEMO_PROMPT='[$(kube_ps1)] '
}
