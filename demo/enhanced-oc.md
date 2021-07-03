# Demo: Enhanced OpenShift CLI

This demo will work you through the major features that Enhanced OpenShift CLI (enhanced oc) provides.

## Getting Started

To verify you have installed the enhanced oc, run `oc` and see if there is a notice started with "An Enhanced Version of OpenShift Client"
at the very beginning.
```shell
oc
```

To login to a cluster for the first time, you will have to specify all information needed to access the cluster.
Let's login to $DEMO_SERVER using $DEMO_USER:
<!--shell
echo "\$DEMO_SERVER=$DEMO_SERVER"
echo "\$DEMO_USER=$DEMO_USER"
-->
```shell
oc login --server $DEMO_SERVER -u $DEMO_USER
```

Next time when you login again, you do not have to input all information as above. Just specify the alias using option `-c`.
This is an option introduced by enhanced oc. See the `oc login` help information:
```shell
oc login --help
```

Now, let's try to login the same cluster using alias $DEMO_CONTEXT_ALIAS:
<!--shell
echo "\$DEMO_CONTEXT_ALIAS=$DEMO_CONTEXT_ALIAS"
-->
```shell
oc login -c $DEMO_CONTEXT_ALIAS
```

## Organize cluster contexts hierarchically

When use the `path/to/context` format to name the context alias for the clusters, you can organize cluster contexts as a tree.
To list the tree:
```shell
gopass ls
```

Each context is saved as a separate file in a directory where the file path maps to the alias `path/to/context`.
All files are stored in `~/.local/share/gopass/stores/root` by default:
```shell
ls -R -l ~/.local/share/gopass/stores/root
```

When you switch among these clusters, use alias `path/to/context` to refer to the target cluster that you want to access.
Let's use $DEMO_CONTEXT_FULL_ALIAS as the alias:
<!--shell
echo "\$DEMO_CONTEXT_FULL_ALIAS=$DEMO_CONTEXT_FULL_ALIAS"
-->
```shell
oc login -c $DEMO_CONTEXT_FULL_ALIAS
```

## Choose among multiple clusters

When only input partial context alias, and the value maps to multiple clusters, enhanced oc allows you to choose one cluster among them.
<!--shell
echo "\$DEMO_CONTEXT_PART_ALIAS=$DEMO_CONTEXT_PART_ALIAS"
-->
<!--shell
__oc_no_fzf=1
-->
```shell
oc login -c $DEMO_CONTEXT_PART_ALIAS
```
<!--shell
__oc_no_fzf=
-->

If you installed fzf, an interactive command-line filter and fuzzy finder, you can use typeahead and fuzzy search to select a context.
Just input partial alias using $DEMO_CONTEXT_PART_ALIAS:
```shell
oc login -c $DEMO_CONTEXT_PART_ALIAS
```