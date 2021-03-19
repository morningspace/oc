## Basic Use

### Login cluster for the first time

Using enhanced oc, you can login cluster in a more efficient and secure manner. To login to a cluster for the first time:
```shell
$ oc login
```

You will be prompted for the URL of the server that you are about to access, the name and password of the login user. These are all features supported by the original oc. Besides that, it will ask you to enter an additional field called `context alias`. It is the shorthand of the full context name that represents which cluster you are accessing and which user account you are using to access this cluster. You will see how the context alias can be used to efficiently manage multiple clusters access later in this document. Here is an example:
```shell
$ oc login
Server [https://localhost:8443]: https://api.cluster-foo.example.com:6443
Username [kubeadmin]:
Password:
Context alias [api-cluster-foo-example-com-6443]: cluster-foo
Login successful.

You have access to 59 projects, the list has been suppressed. You can list all projects with 'oc projects'

Using project "default".
Save context 'cluster-foo' into secret store...
Context saved successfully.
```

Of course just as the original oc does, you can specify all the above information as the command line arguments when you run `oc login`. However, to avoid the unexpected exposure of your login information in the command history, the list of previously used commands in the terminal, it is not recommended to specify the information such as user password as command argument of `oc login`.

**NOTE:**

When run `oc login`, you may see some warnings as below. Don't worry. This is because your gopass store has not been setup for remote sharing which will be discussed later in this document. Also, if you are using newer version of gopass such as `1.12.x`, you will not see such warning:
```
Warning: git has no remote. Ignoring auto-push option
Run: gopass git remote add origin ...
```

### Login cluster using context alias

For some reason, you may have to re-login to a cluster. This is normal when the login credential to the cluster is expired. In such case, you need to re-run `oc login`. Different from the original oc, you don't have to provide all the information that you have already input the first time when you run `oc login` to access the cluster. This time the only information it needs is the `context alias`:
```shell
$ oc login -c cluster-foo
Read context 'cluster-foo' from secret store...
Context loaded successfully.
Login successful.

You have access to 59 projects, the list has been suppressed. You can list all projects with 'oc projects'

Using project "default".
```

This is because all the information you previously input for this cluster has been saved in gopass secret store with a context alias pointing to it. So, you just specify the context alias, and the enhanced oc will load all the necessary information by the context alias in order to login the cluster.

This is truely powerful for two reasons:
* **Security**: In a real project with many clusters bumping up and down, it is usally very hard for people to remember the password of every single cluster. As a result, you may have to write down the passwords somewhere in plain text which is not a good practice from security perspective. By using the enhanced oc, since clusters access information including the passwords are all encrypted and saved in a secret store. You don't need to worry about the sensitive information disclosure.
* **Efficiency**: It is not just the password that is hard to remember in a real project, usually the server URL of the short-lived cluster is also hard to remember. By using the enhanced oc, these information are all saved in the secret store, and referenced by a context alias which is human-memorable. With that, for the access to a partilucar cluster, you only need to remember the context alias. This is very helpful if you have many clusters to manage.
