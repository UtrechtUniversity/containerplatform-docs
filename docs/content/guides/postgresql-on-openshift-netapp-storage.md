## Deploy postgresql on OpenShift with netapp

## Introduction
Postgresql only starts when the username / userid the application runs as is the same as the owner of the data directory.
The userid used by netapp is 99, so we need to tell postgres to also runs as userid 99 and don't use a random userid, which is the default on OpenShift.
Normally we don't want this but for postgresql is the only way this works.
Mariadb for example can run perfectly fine with random userid's.

## Prerequisites

To follow this guide, you need: 

- an account and project on the Container Platform.
- the OpenShift client tools installed. 
- helm installed
- You need to have enough permissions to deploy to a project (setup by a key user)

## Example deployment with a helm chart from bitnami

### Install bitnami postgresql with default values file.

First, install the helm chart on OpenShift, with all the default settings.

```bash
$ helm install postgres oci://registry-1.docker.io/bitnamicharts/postgresql --version=16.4.5
Pulled: registry-1.docker.io/bitnamicharts/postgresql:16.4.5
Digest: sha256:7e2bd8ed9d2ac7673a5730141301d038fa7b7cf130503c8dd5dcbc6ddfe0e377
NAME: postgres
LAST DEPLOYED: Thu Jan 23 12:40:19 2025
NAMESPACE: uu-boon0031
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: postgresql
CHART VERSION: 16.4.5
APP VERSION: 17.2.0
...
```

```bash
$ oc get pods
NAME                    READY   STATUS             RESTARTS     AGE
postgres-postgresql-0   0/1     CrashLoopBackOff   2 (7s ago)   38s
```

```bash
$ oc logs postgres-postgresql-0
postgresql 11:42:11.84 INFO  ==> 
postgresql 11:42:11.84 INFO  ==> Welcome to the Bitnami postgresql container
postgresql 11:42:11.84 INFO  ==> Subscribe to project updates by watching https://github.com/bitnami/containers
postgresql 11:42:11.84 INFO  ==> Did you know there are enterprise versions of the Bitnami catalog? For enhanced secure software supply chain features, unlimited pulls from Docker, LTS support, or application customization, see Bitnami Premium or Tanzu Application Catalog. See https://www.arrow.com/globalecs/na/vendors/bitnami/ for more information.
postgresql 11:42:11.93 INFO  ==> 
postgresql 11:42:11.94 INFO  ==> ** Starting PostgreSQL setup **
postgresql 11:42:12.14 INFO  ==> Validating settings in POSTGRESQL_* env vars..
postgresql 11:42:12.24 INFO  ==> Loading custom pre-init scripts...
postgresql 11:42:12.24 INFO  ==> Initializing PostgreSQL database...
postgresql 11:42:12.34 INFO  ==> pg_hba.conf file not detected. Generating it...
postgresql 11:42:12.34 INFO  ==> Generating local authentication configuration
```
The container does not start but no obvious error message is shown. But the problem is the persistent volume as explained above.

### example deployment without persistent storage

To show that it really is the persistent storage that is causing the problem, you can install the helm chart without persistent storage:

```bash
$ helm install postgres oci://registry-1.docker.io/bitnamicharts/postgresql --version=16.4.5 --set primary.persistence.enabled=false
Pulled: registry-1.docker.io/bitnamicharts/postgresql:16.4.5
Digest: sha256:7e2bd8ed9d2ac7673a5730141301d038fa7b7cf130503c8dd5dcbc6ddfe0e377
NAME: postgres
LAST DEPLOYED: Thu Jan 23 12:55:48 2025
NAMESPACE: uu-boon0031
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: postgresql
CHART VERSION: 16.4.5
APP VERSION: 17.2.0
```

```bash
$ oc get pods
NAME                    READY   STATUS    RESTARTS   AGE
postgres-postgresql-0   1/1     Running   0          46s
```

```bash
$ oc logs postgres-postgresql-0
....
postgresql 11:55:58.93 INFO  ==> ** Starting PostgreSQL **
2025-01-23 11:55:59.036 GMT [1] LOG:  pgaudit extension initialized
2025-01-23 11:55:59.045 GMT [1] LOG:  starting PostgreSQL 17.2 on x86_64-pc-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit
2025-01-23 11:55:59.046 GMT [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2025-01-23 11:55:59.046 GMT [1] LOG:  listening on IPv6 address "::", port 5432
```

### modify values file to use netapp persistent storage

To be able to make this work we should do some modifications:

* create a serviceaccount and set it in the helm chart (or let helm create it)
* use a non root scc
* run with userid and groupid 99

#### create service account
```
$ oc create sa postgresql
serviceaccount/postgresql created
```

#### add scc to service account
```bash
$ oc adm policy add-scc-to-user nonroot-v2 -z postgresql
clusterrole.rbac.authorization.k8s.io/system:openshift:scc:nonroot-v2 added: "postgresql"
```
Note that only cluster admins can set the scc on a service account. The Linux team can help with that. 

#### modify helm chart values to use scc and userid 99
We need to override some helm chart default values:

```bash
$ cat custom-values.yaml 
global:
  compatibility:
    openshift:
      adaptSecurityContext: disabled     # this prevents from using random userid's
primary:
  containerSecurityContext:
    seLinuxOptions: 
      level: "s0:c33,c22"
    runAsUser: 99                        # run postgresql with uid 99
    runAsGroup: 99                       # run postgresql with gid 99
serviceAccount:
  create: false                          # set this to true if you want helm to create the service account.
  name: postgresql
```

```bash
$ helm install postgres oci://registry-1.docker.io/bitnamicharts/postgresql --version=16.4.5 -f custom-values.yaml 
Pulled: registry-1.docker.io/bitnamicharts/postgresql:16.4.5
Digest: sha256:7e2bd8ed9d2ac7673a5730141301d038fa7b7cf130503c8dd5dcbc6ddfe0e377
NAME: postgres
LAST DEPLOYED: Thu Jan 23 13:06:56 2025
NAMESPACE: uu-boon0031
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: postgresql
CHART VERSION: 16.4.5
APP VERSION: 17.2.0
...
```

```bash
$ oc rsh postgres-postgresql-0 
$ bash
99@postgres-postgresql-0:/$ id
uid=99(99) gid=99(99) groups=99(99),1001
99@postgres-postgresql-0:/$ ls -l /bitnami/postgresql/data/
total 88
drwx------. 5 99 99 4096 Jan 23 12:03 base
drwx------. 2 99 99 8192 Jan 23 12:08 global
drwx------. 2 99 99 4096 Jan 23 12:03 pg_commit_ts
drwx------. 2 99 99 4096 Jan 23 12:03 pg_dynshmem
-rw-------. 1 99 99 2640 Jan 23 12:03 pg_ident.conf
drwx------. 4 99 99 4096 Jan 23 12:06 pg_logical
drwx------. 4 99 99 4096 Jan 23 12:03 pg_multixact
drwx------. 2 99 99 4096 Jan 23 12:03 pg_notify
drwx------. 2 99 99 4096 Jan 23 12:03 pg_replslot
drwx------. 2 99 99 4096 Jan 23 12:03 pg_serial
drwx------. 2 99 99 4096 Jan 23 12:03 pg_snapshots
drwx------. 2 99 99 4096 Jan 23 12:07 pg_stat
drwx------. 2 99 99 4096 Jan 23 12:03 pg_stat_tmp
drwx------. 2 99 99 4096 Jan 23 12:03 pg_subtrans
drwx------. 2 99 99 4096 Jan 23 12:03 pg_tblspc
drwx------. 2 99 99 4096 Jan 23 12:03 pg_twophase
-rw-------. 1 99 99    3 Jan 23 12:03 PG_VERSION
drwx------. 4 99 99 4096 Jan 23 12:03 pg_wal
drwx------. 2 99 99 4096 Jan 23 12:03 pg_xact
-rw-------. 1 99 99   88 Jan 23 12:03 postgresql.auto.conf
-rw-------. 1 99 99  249 Jan 23 12:07 postmaster.opts
-rw-------. 1 99 99   79 Jan 23 12:07 postmaster.pid
```

```bash
$ oc logs postgres-postgresql-0 
postgresql 12:07:07.03 INFO  ==> Welcome to the Bitnami postgresql container
...
...
2025-01-23 12:07:08.850 GMT [1] LOG:  database system is ready to accept connections
```
