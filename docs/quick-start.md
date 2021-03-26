## Quick Start

This document is aimed to help you setup and run the enhanced oc quickly. If you want to learn more details about install, setup, use of enhanced oc, please read other documents.

### Install

Before you start to install enhanced oc, please make sure the following prereqs are installed:
* gpg: for data encryption and decryption
* git: for encrypted data storing and sharing
* gopass: run on top of gpg and git for secret data management
* oc: the original OpenShift CLI for cluster manipulation

To install git and gpg:
```shell
# MacOS
$ brew install gnupg2 git
# RHEL & CentOS
$ brew install gnupg2 git
# Ubuntu & Debian
$ apt-get install gnupg2 git
```

To install gopass, it's recommended to download the latest version with appropriate distribution from the repository [releases](https://github.com/gopasspw/gopass/releases) page. For example, download the darwin or linux package for MacOS or Linux, extract the package and find the gopass executable, put it somewhere that can be reached via `$PATH`, then you are done.

To install oc, please refer to the [OpenShift documentation](https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html#installing-openshift-cli).

After you get the prereqs installed, download the shell from GitHub:
```shell
$ curl -OL https://raw.githubusercontent.com/morningspace/oc/master/oc.sh
```

Add the following line to your `.bashrc` if you use Bash or whatever initialization file is used by your shell:
```shell
[[ -f /path/to/oc.sh ]] && source /path/to/oc.sh
```

Then open a new terminal and run `oc` to verify the installation. You should see a notice started with "An Enhanced Version of OpenShift Client" at the head of the normal oc help information.

### Setup

gopass depends on gpg for encryption and decryption. You must generate a private and public key pair at first:
```shell
$ gpg --full-generate-key
```

Choose `RSA and RSA` as key type, keysize to be `2048`, `key does not expire`, input your user name as real name, email address, and passphrase.

You should also add the following lines to your `.bashrc` if you use Bash or whatever initialization file is used by your shell:
```shell
export GPG_TTY=$(tty)
```

Init the secret store:
```shell
$ gopass init
```

Choose the private key we created above for encrypting secrets, enter your email address for git config.

Now you can run the enhanced oc. When you run `oc login` to log into a cluster for the first time, you will need to provide username and password along with an alias to the cluster. The cluster access information will then be saved into a secret store, so next time when you re-login to the same cluster, you just need to specify the alias, it will load the username and password from the secret store by the alias. More on the use of enhanced oc, please read [Using Enhanced oc](using-enhanced-oc.md).

### Setup for team member

**NOTE:**

> If you run the enhanced oc only for personal use, then you can ignore this section. For those who are team members do not own the secret store, you just need to generate the private and public key pair, export the public key and send it to store owner, then wait for the reply before you can clone the remote store to your local machine. More on this, please read below instructions.

If you want to share your cluster access information saved in your local secret store to your team members. Add git remote and push local secret store to the remote:
```shell
$ gopass git remote add origin git@github.example.com:william/team-clusters.git
$ gopass git push origin master
```

In order to get your team members onboard. Please ask them to install all needed programs by following the instructions in [Install](#Install) section and generate the private and public key pair by following the instructions in [Setup](#Setup) section.

Then ask them to export the public key and send to you. To find the public key ID:
```shell
$ gpg --list-keys --keyid-format LONG
/root/.gnupg/pubring.gpg
------------------------
pub   2048R/93E7B0300BB9C91B 2021-03-17
uid                          Nicole <nicole@example.com>
sub   2048R/3AE8C980579D103C 2021-03-17
```

Pick the one that matches your team member's name and email address, copy the key ID in `pub` section, in this case, `93E7B0300BB9C91B`. Then export the public key to a file using the key ID:
```shell
$ gpg --armor --export 93E7B0300BB9C91B > nicole_pub.gpg
```

After you recieve the public key from your team member, import into your local machine:
```shell
$ gpg --import nicole_pub.gpg
```

Add it as recipient into the secret store:
```shell
$ gopass recipients add 93E7B0300BB9C91B
```

Then sign the public key using your own private key and trust it:
```shell
$ gpg --edit-key 93E7B0300BB9C91B
lsign
trust
save
```

Re-add it as recipient to trigger the secrets re-encryption in your local store:
```shell
$ gopass recipients rm 93E7B0300BB9C91B
$ gopass recipients add 93E7B0300BB9C91B
```

All the above changes that you made locally will be auto-synced to the remote store.

Now you can ask your team members to clone the remote store to their local machines. Please make sure your team members have been invited as collaborators to your remote store or GitHub repository. Your team member can clone the store from GitHub:
```shell
$ gopass --yes setup --remote git@github.example.com:william/team-clusters.git --alias team-clusters --name Nicole --email "nicole@example.com"
```

Then they can run `oc login` and use the alias defined by you to login clusters.
