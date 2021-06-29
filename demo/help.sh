# The demo cluster you want to access
DEMO_SERVER=
DEMO_CONTEXT_ALIAS=
DEMO_CONTEXT_FULL_ALIAS=
DEMO_CONTEXT_PARTIAL_ALIAS=

function tutorial::setup {
  if [[ -z $DEMO_SERVER || -z $DEMO_CONTEXT_ALIAS || -z $DEMO_CONTEXT_FULL_ALIAS || -z $DEMO_CONTEXT_PARTIAL_ALIAS ]]; then
    echo '$DEMO_SERVER and $DEMO_CONTEXT_ALIAS should not be empty.'
    return 1
  fi
}
