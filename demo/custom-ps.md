# Demo: Customize the Shell Prompt

This demo will show you how enhanced oc customizes the shell prompt to display the alias of the cluster that you are working on.

## Integrate with kube-ps1

kube-ps1 is a script that allows you to add the current cluster context and namespace to the shell prompt. It is helpful when you
have many clusters to manage and need to switch among them from time to time. By looking at the shell prompt, you can quickly know
the cluster that you are working on to avoid any mistake made against the wrong cluster.

The enhanced oc can integrate with kube-ps1 when you have kube-ps1 installed. It will customize the shell prompt further to replace 
the full cluster context name with the context alias, which is much shorter and more human readable.

When you have multiple clusters already logged in using enhanced oc, try to switch among them and see how shell prompt is changed:
<!--shell
tutorial::exec --include 'oc|gopass'
-->