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

function tutorial::setup {
  if [[ -z $DEMO_SERVER || -z $DEMO_USER || -z $DEMO_CONTEXT_ALIAS || -z $DEMO_CONTEXT_FULL_ALIAS || -z $DEMO_CONTEXT_PART_ALIAS ]]; then
    echo '$DEMO_* environment variables should not be empty.'
    return 1
  fi
}
