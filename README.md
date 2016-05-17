# mkFreeIPA
Make a persistent FreeIPA docker container PDQ based on the awesome container by [adelton](https://github.com/adelton/docker-freeipa)


### Usage

##### TLDR do it for me!

`make auto`  will automatically attempt to configure your IPA server and fire up the temporary instance

wait for

```
FreeIPA server configured.  
```

then `make next` when that finishes `make jabberinit` then you can `make jabber`

you now have a full single sign on solution and an ejabberd server to test it out (assuming all went well, if not `make rm` and `make hardclean` and try manually below)

#### Manual Install

or you can walk through the prompts and manually answer some questions

`make temp` will make a temporary ephemeral instance that we can grab the initial directory structure from

in either case watch the logs and wait for FreeIPA to finish installing, `make entropy` can speed this process up tremendously by supplying some extra entropy

there are a few errors about symlinks that can be ignored for now

```
These files are required to create replicas. The password for these                                                                         │··················
files is the Directory Manager password                                                                                                     │··················
Created symlink from /etc/systemd/system/container-ipa.target.wants/ipa-server-update-self-ip-address.service to /usr/lib/systemd/system/ipa│··················
-server-update-self-ip-address.service.                                                                                                     │··················
Created symlink from /etc/systemd/system/container-ipa.target.wants/ipa-server-upgrade.service to /usr/lib/systemd/system/ipa-server-upgrade│··················
.service.                                                                                                                                   │··················
Failed to execute operation: Too many levels of symbolic links                                                                              │··················
FreeIPA server configured.  
```

when this finishes (not before) you can then
`make grab` which will grab those directories for you once FreeIPA has finished installing
grab will make a `datadir` in the current directory and copy `/data` out
of the temporary container to be used in a persistent setup

the path to the data directory is then echo'd into
FREEIPA_DATADIR
to be used by the `prod` step later

`make rmtemp` will clean up our temporary containers, but will not delete the `datadir`

I tend to move the datadir at this point (e.g. `mv datadir /exports/freeipa/`), then update FREEIPA_DATADIR appropriately

`make prod` will then use the `datadir` and start up our container in persistent mode

login to the FQDN you gave earlier as admin with the password you supplied, add a user, if you want to test this setup using ejabberd continue on

### Ejabberd

##### Warning this section is largely supplanted but `make jabberinit` and `make jabber` read on for historical purposes

The freeIPA docs have an article [here](http://www.freeipa.org/page/EJabberd_Integration_with_FreeIPA_using_LDAP_Group_memberships)

which you will need to follow, as getting the web interface to create the system user is something I have not done before, its not hard their way

first from your mkFreeIPA directory, enter the running FreeIPA container with `make enter`

now you can run the `ldapmodify` command directly on your running instance

create the  `/root/jabber.ldif` as normal, but realize if you leave it in /root it will disappear upon restarting the container, instead use /data for anything you want to survive restarts

you can now run `make jabber` which will prompt you for the information it needs this will correspond to the example data given:

```
{ldap_servers, ["ds01.example.com"]}.
{ldap_uids, [{"uid"}]}.
{ldap_filter, "(memberOf=cn=jabber_users,cn=groups,cn=accounts,dc=example,dc=com)"}.
{ldap_base, "dc=example,dc=com"}.
{ldap_rootdn, "uid=ejabberd,cn=sysaccounts,cn=etc,dc=example,dc=com"}.
{ldap_password, "secret123"}.
```

### Replicants

`make prepareMasterForReplicant`  will get the master prepd, you will be prompted for the hostname of the replicant

copy the resulting mkFreeIPA.tgz to the replicant host

untar the mkFreeIPA.tgz over your existing mkFreeIPA directory

this will add the necessary password files

`make prepareReplica` this will prep the replica

`make replica` if everything has gone well up to now you should have a replica freeipa server

replica ejabberd is a WIP
