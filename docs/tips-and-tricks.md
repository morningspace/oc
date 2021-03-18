## Tips and Tricks

### Avoid the passphrase prompt every time on Linux and MacOS

When you generate the public and private key pair using `gpg`, you will be prompted to input a passphrase. Usually it is recommended that you should pick a very long passphrase, not just a simple password. It should be stronger than any secret you save in the secret store using `gopass`.

However, that makes it annoying as anytime when you read or write the secret store, you will be prompted for the passphrase.

On MacOS, it is quit easy to avoid this. You just need to add the passphrase into the Keychain Access.

On Linux, you can configure `gpg-agent` to save your repetitive typing where the agent is used to cache the passphrase you input. You can put your custom settings into `gpg-agent.conf` in `~/.gnupg` directory. For example:
```shell
$ cat << EOF >>~/.gnupg/gpg-agent.conf

# Set the default cache time to 1 day.
default-cache-ttl       86400
default-cache-ttl-ssh   86400

# Set the max cache time to 30 days.
max-cache-ttl           2592000
max-cache-ttl-ssh       2592000
EOF
```

This will set the default cache time to 1 day, and the max cache time to 30 days. In order to have the agent pick up the settings, you need to reload the agent. Before reload, you can check the current settings:
```shell
$ gpgconf --list-options gpg-agent | grep 'default-cache-ttl\|max-cache-ttl'
gpgconf: warning: can not open config file /root/.gnupg/gpg-agent.conf: No such file or directory
default-cache-ttl:24:0:expire cached PINs after N seconds:3:3:N:600::
default-cache-ttl-ssh:24:1:expire SSH keys after N seconds:3:3:N:1800::
max-cache-ttl:24:2:set maximum PIN cache lifetime to N seconds:3:3:N:7200::
max-cache-ttl-ssh:24:2:set maximum SSH key lifetime to N seconds:3:3:N:7200::
```

Then reload the agent:
```shell
$ gpg-connect-agent reloadagent /bye
```

To verify if the new settings have been picked up:
```shell
$ gpgconf --list-options gpg-agent
default-cache-ttl:24:0:expire cached PINs after N seconds:3:3:N:600::86400
default-cache-ttl-ssh:24:1:expire SSH keys after N seconds:3:3:N:1800::86400
max-cache-ttl:24:2:set maximum PIN cache lifetime to N seconds:3:3:N:7200::2592000
max-cache-ttl-ssh:24:2:set maximum SSH key lifetime to N seconds:3:3:N:7200::2592000
```

References

* https://askubuntu.com/questions/805459/how-can-i-get-gpg-agent-to-cache-my-password
* https://unix.stackexchange.com/questions/614737/how-to-cache-gpg-key-passphrase-with-gpg-agent-and-keychain-on-debian-10
* https://unix.stackexchange.com/questions/395875/gpg-does-not-ask-for-password

### Suppress the message "you need a passphrase to unlock the secret"

When you decrypt data using `gopass show` on some Linux machine, it will print the message as below for the passphrase even that you have already cached it using `gpg-agent`.
```shell
$ gopass show team-cluster-contexts/dev-env/cluster-foo

You need a passphrase to unlock the secret key for
user: "Nicole <nicole@example.com>"
2048-bit RSA key, ID 1056C9D6, created 2021-03-17 (main key ID 72C9C86E)
```

This is actually caused by `gpg` which is a dependency of `gopass`. You will see the same message when use `gpg` to decrypt data and the message can not be suppressed even you redirect the `stderr` output to `/dev/null`:
```shell
$ gpg -d ~/.local/share/gopass/stores/team-cluster-contexts/dev-env/cluster-foo.gpg 2>/dev/null

You need a passphrase to unlock the secret key for
user: "root <moyingbj@cn.ibm.com>"
2048-bit RSA key, ID 21DEB23E, created 2021-03-13 (main key ID F8D7E33F)
```

This is because old version of `gpg` such as `2.0.22` does not use `stderr` to print the message, instead it uses `tty`. To set `no-tty` in `gpg.conf` can avoid the message:
```shell
echo 'no-tty' >> ~/.gnupg/gpg.conf
```

But this will break the passphrase input. It seems this issue has been fixed in newer version of `gpg`, such as `2.2.20`.

References:

* https://stackoverflow.com/questions/37763170/git-signed-commits-how-to-suppress-you-need-a-passphrase-to-unlock-the-secret
* https://unix.stackexchange.com/questions/212950/silent-gnupg-password-request-with-bash-commands/212953#212953
