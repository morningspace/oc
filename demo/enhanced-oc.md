# Demo: Enhanced OpenShift CLI

This demo will work you through the major features that Enhanced OpenShift CLI (enhanced oc) provides.

## Getting Started

To verify you have installed the enhanced oc, run `oc` and you should see a notice started with "An Enhanced Version of OpenShift Client" at the head of the normal oc help information.
```shell
oc
```

To login to a cluster for the first time, you will have to specify all information needed to access the cluster.
```shell
echo "The demo cluster you want to access: $DEMO_SERVER"
oc login --server $DEMO_SERVER
```

Next time when you login again, you do not have to input all information as above. Just specify the alias that maps to the cluster using option `-c`. This is a new option introduced by enhanced oc. See the `oc login` help information:
```shell
oc login -h
```

Now, let's try login using this alias:
```shell
echo "The demo context alias you specified: $DEMO_CONTEXT_ALIAS"
oc login -c $DEMO_CONTEXT_ALIAS
```

## Organize cluster contexts hierarchically

When use the `path/to/context` format to name the context alias for the clusters, you can organize cluster contexts as a tree. To list the tree:
```shell
gopass ls
```

When you switch among these clusters, use the `path/to/context` alias to refer to the target cluster that you want to access:
```shell
echo "The demo context alias you specified: $DEMO_CONTEXT_FULL_ALIAS"
oc login -c $DEMO_CONTEXT_FULL_ALIAS
```

## Choose among multiple clusters

If you installed fzf, an interactive command-line filter and fuzzy finder, you should be able to use typeahead and fuzzy search to select a context. Just input part of the alias:
```shell
echo "The demo context alias you specified: $DEMO_CONTEXT_PARTIAL_ALIAS"
oc login -c $DEMO_CONTEXT_PARTIAL_ALIAS
```