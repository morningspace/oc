## Installation

The enhanced OpenShift Client (oc) is not a replacement of [the original OpenShift Client](https://github.com/openshift/oc/). It is essentially a shell on top of the original client. Before you install this client, you must install the original one first. To install the original client, you can refer to [OpenShift documentation](https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html#installing-openshift-cli).

After you get the original client installed, it is easy to install the enhanced one since it is just a single script. You can download it from the git repository:
```shell
$ curl -OL https://raw.githubusercontent.com/morningspace/oc/master/oc.sh
```

Then add the following line to your `.bashrc` if you use Bash or whatever initialization file is used by your shell:
```shell
[[ -f /path/to/oc.sh ]] && source /path/to/oc.sh
```

To validate the installation:
```shell
$ oc --help
```

If you see a notice at the head of the normal oc help information as below:
```shell
An Enhanced Version of OpenShift Client

NOTICE:

This is not a replacement of the original OpenShift Client: https://github.com/openshift/oc/,
but a shell on top of it that requires the original client to be installed at first. For more
information, please check: https://github.com/morningspace/oc/.
```

That means you have successfully installed the enhanced oc and the original oc has been nicely "hacked" with this shell. It supports all the original oc commands and their options, plus some additional cool features that will be explored later in this document.

**NOTE:**

The enhanced OpenShift Client has been tested on MacOS and Linux.
