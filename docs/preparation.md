## Preparation

The enhanced OpenShift CLI depends on `gopass` to store data securely. It requires you to install `gopass` first. This docoment is intended to walk you through all necessary setups needed before and after you install `gopass`.

### Install Dependencies

gopass needs some external programs to work:

* gpg: for data encryption and decryption, preferably in version 2 or later
* git: for encrypted data storing and sharing

Assume you have already had these programs installed. If not, please refer to the [gopass documentation](https://github.com/gopasspw/gopass/issues#pre-installation-steps). To make sure if these programs are installed:
```shell
$ gpg --version # or gpg2 --version
$ git --version
```

### Setup GPG Key Pair

gopass depends on the gpg program for encryption and decryption. You must have a suitable key pair to make it work. To list your current keys, you can do:
```shell
$ gpg --list-secret-keys
```

You can choose an existing key from the list. If you don't have any key, or you want to use a new key, then you can do:
```shell
$ gpg --full-generate-key
```

**NOTE:**

You may notice some gpg installations may use different option. The above command can work on my MacOS laptop and a RHEL8 machine, but it does not work on another RHEL7 machine, where I have to use `gpg --gen-key` instead. Please refer to the help information of the gpg that you use if you met problems.

After run above command, you will be presented with several questions. Please refer to the [gopass documentation](https://github.com/gopasspw/gopass/issues#set-up-a-gpg-key-pair) on how to answer these questions. After you finish the questionnaire, gpg will start to generate the key pair for you.

**NOTE:**

It may take more time than you expect to generate the key pair which makes you think gpg is hung. Just be patient and wait for gpg to be finished. Or as it's recommended in gopass doc, you can have either `rng-tools` or `haveged` installed to speed up key generation.

After the program is finished, you will have a public and private key pair for later use.

### Git and GPG

gopass essentially uses git repository to store all encrypted data. This allows gopass to share the data to the remote using git. Any change made to the data will be performed as a git commit. gopass will configure git to sign commits by default, so you should make sure that git can interface with gpg by telling git to use the key we choose when signs commits.

As a private key is required for signing commits, we need to know the private key ID. To list all your private keys:
```shell
$ gpg --list-secret-keys --keyid-format LONG
/root/.gnupg/secring.gpg
------------------------
sec   2048R/FB8C81C172C9C86E 2021-03-17
uid                          William <william@example.com>
ssb   2048R/B729258E1056C9D6 2021-03-17
```

From the list, copy the key ID you'd like to use in `sec` line. In this example, it is `FB8C81C172C9C86E`, then config git to use it as the signing key:
```shell
$ git config --global user.signingkey FB8C81C172C9C86E
```

**NOTE:**

Some gpg installations on Linux may require you to use `gpg2 --list-keys --keyid-format LONG` to view the key list. In this case you will also need to configure git to use gpg2 by running `git config --global gpg.program gpg2`.

If you aren't using the GPG suite, you should also add the following lines to your `.bashrc` if you use Bash or whatever initialization file is used by your shell:
```shell
export GPG_TTY=$(tty)
```

To make sure gpg itself works, you can run gpg to make a clear text signature:
```shell
$ echo "test" | gpg --clearsign
```

If everything works as expected, you should see the output similar as below:
```
You need a passphrase to unlock the secret key for
user: "William <william@example.com>"
2048-bit RSA key, ID 72C9C86E, created 2021-03-17

-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

test
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v2.0.22 (GNU/Linux)

iQEcBAEBAgAGBQJgUdBhAAoJEPuMgcFyychuLsoH/iIN1wICdA2So0TyDLYGChVP
IjRaO0kYE/2Cfgk6tpz6ci7qQRpd7xEibd/2SN3Qgs+bwwzASzEmEa7bmtF9Tp4Q
79E01/3qmZ9powv7xCZ7m9LZeRqe/OrEOIfNPvfRJA0/rcLrwojzQ46v5tPhvMgh
LWf/OOYFt2b92+DiXjg5M/Fq7qpFqNkJKkqPdScHh2MrURRyM3LziJUHHbFbt58=
=sRm2
-----END PGP SIGNATURE-----
```

Now you can test if git will use the specified key to sign the commits on your local branch. This is done by adding the `-S` flag to the `git commit` command:
```shell
$ mkdir some-dir
$ cd some-dir
$ git init
$ touch foo
$ git add foo
$ git commit -S -m "test"
```

To verify the commit is signed by the key:
```shell
$ git log --show-signature
commit 0051ff71a339338db381744eda24203095bc0c55
gpg: Signature made Wed Mar 17 03:04:24 2021 PDT using RSA key ID 72C9C86E
gpg: Good signature from "William <william@example.com>"
Author: William <william@example.com>
Date:   Wed Mar 17 03:04:19 2021 -0700

    test
```

To sign all commits by default in any local repository on your machine, you can do:
```shell
$ git config --global commit.gpgsign true
```

### Install gopass

After you finish all the above steps, you can go ahead to install gopass. The gopass installation is quite straightforward, please refer to the [gopass documentation](https://github.com/gopasspw/gopass/issues#installation-steps) to see the instructions for gopass installation steps on different platforms.

**NOTE:**

For old RHEL distribution, `yum` is used to install package. The gopass installation requires `yum-plugin-copr` to be installed first:
```shell
$ yum -y install yum-plugin-copr
```

After then, you can install gopass:
```shell
$ yum copr enable daftaupe/gopass
$ yum install gopass
```

### Init gopass

Before you start to use the enhanced OpenShift CLI, you need to initialize a store using gopass to host all encrypted data that will be read and written by the enhanced OpenShift CLI. Just do:
```shell
$ gopass init
```

This will prompt you for which GPG key you want to associate the store with. Let's use the same key that we specify to sign the git commits. It will also ask you to enter an email address for the store git config. Since the store is git repository, this will config the git repository to use the user with the specified email address as the author of each git commit.

After you finish the input, it will create a store directory in your home directory. Usually it is `~/.local/share/gopass/stores/root`.

### References

* https://docs.github.com/en/github/authenticating-to-github/telling-git-about-your-signing-key
* https://docs.github.com/en/github/authenticating-to-github/signing-commits
* https://stackoverflow.com/questions/41052538/git-error-gpg-failed-to-sign-data
