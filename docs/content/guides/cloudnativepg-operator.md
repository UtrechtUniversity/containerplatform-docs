# CloudnativePG

We can't write better documentation about CloudnativePG than the CloudnativePG team itself. 
So we refer you to their documentation and code repository.

Find the docs guide at <a href="https://cloudnative-pg.io/documentation/1.27/" target="_blank">cloudnative-pg.io</a>  
Find the code at <a href="https://github.com/cloudnative-pg" target="_blank">GitHub cloudnative-pg</a>

## Specifics for our OpenShift Container Platform

Use storageClass: `thin-csi`  
Use postgresUID: `26`  
Use postgresGID: `26`  
Use endpointURL: `https://s3.uu.nl` for S3 object storage  
Use affinity block under spec in `cluster.spec.affinity` to schedule the cluster(postgres pods) pods on the special database nodes.  
```yaml
---
kind: Cluster
apiVersion: postgresql.cnpg.io/v1
metadata:
  name: <example-name>
  namespace: <example-namespace>
spec:
  affinity:
    nodeSelector:
      node-role.kubernetes.io/db: ""
    tolerations:
    - key: node-role.kubernetes.io/db
      operator: Exists
      effect: NoSchedule
```
Specs of the db nodes (minimal 4 nodes are always running in our platform, autoscaling is set up):
```bash
CPU: 16 vCPU
Memory: 32 GB
Disk: 240+ GB (SSD)
Taints: node-role.kubernetes.io/db
```
There is a machineautscaler setup for db nodes.
```yaml
---
apiVersion: "autoscaling.openshift.io/v1beta1"
kind: "MachineAutoscaler"
spec:
  minReplicas: 4
  maxReplicas: 12
```

### Backup possibilities with CloudnativePG on our platform
We support two types of backups for CloudnativePG:
#### 1. Volume snapshot for backups
Our storageclass `thin-csi` supports volume snapshots, on how to use the snapshot backup features, see the official docs: <a href="https://cloudnative-pg.io/documentation/1.27/appendixes/backup_volumesnapshot/#about-standard-volume-snapshots" target="_blank">snapshot feature</a>  
#### 2. S3 Object Storage for backups
Prerequisites:  

- [x] **S3 bucket (contact our storageteam)**  
- [x] **S3 credentials (access key id and secret access key)**  

You can use the barman plugin to back up your cluster (databases) to our S3 object storage.
If you want to use the barman plugin, you need to create a secret with your S3 credentials, and an ObjectStore object. See the example below.

### Example of a minimal cluster

```yaml
---
kind: Cluster
apiVersion: postgresql.cnpg.io/v1
metadata:
  name: cluster-example
  namespace: example-namespace
spec:
  affinity:
    nodeSelector:
      node-role.kubernetes.io/db: ""
    tolerations:
    - key: node-role.kubernetes.io/db
      operator: Exists
      effect: NoSchedule
  description: "CloudNativePG test Cluster"
  instances: 3
  bootstrap:
    initdb:
      database: app
      owner: app
      secret:
        name: app-secret
  logLevel: info
  primaryUpdateStrategy: unsupervised
  storage:
    size: 20Gi
    storageClass: thin-csi
  walStorage:
    size: 20Gi
    storageClass: thin-csi
  postgresUID: 26
  postgresGID: 26
  plugins:
    - name: barman-cloud.cloudnative-pg.io
      isWALArchiver: true
      parameters:
        barmanObjectName: cnpg-netapps3-store-test
```
???+ warning "keep size the same for storage and walStorage"
    It is advised to keep the size of `storage.size` and `walStorage.size` the same.
    Otherwise, your app could run into issues when the disk is full.  

### Example of a minimal objectstore setup

```yaml
---
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: cnpg-netapps3-store-test
  namespace: example-namespace
spec:
  configuration:
    destinationPath: s3://<name of the bucket you created>/
    endpointURL: 'https://s3.uu.nl'
    s3Credentials:
      accessKeyId:
        name: netapps3-creds
        key: ACCESS_KEY_ID
      secretAccessKey:
        name: netapps3-creds
        key: ACCESS_SECRET_KEY
    wal:
      compression: bzip2

---
apiVersion: v1
data:
  ACCESS_KEY_ID: dfdfkekdgDDGDGDDDFdf=
  ACCESS_SECRET_KEY: DFDGGDDDG33ggsshha==
kind: Secret
metadata:
  name: netapps3-creds
  namespace: example-namespace
type: Opaque
```
???+ info "`compression: bzip2`"
    You can choose the algorithm, see the docs at: <a href="https://cloudnative-pg.io/documentation/1.27/appendixes/backup_barmanobjectstore/#compression-algorithms" target="_blank">Compression algorithms</a>

### Example of backup configuration

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata:
  name: backup-rene
  namespace: example-namespace
spec:
  cluster:
    name: cluster-example
  method: plugin
  pluginConfiguration:
    name: barman-cloud.cloudnative-pg.io
```

#### Scheduled
```yaml
---
kind: ScheduledBackup
apiVersion: postgresql.cnpg.io/v1
metadata:
  name: scheduledbackup-sample
  namespace: example-namespace
spec:
  immediate: true
  cluster:
    name: cluster-example
  schedule: 0 0 0 * * *
  method: plugin
  pluginConfiguration:
    name: barman-cloud.cloudnative-pg.io
```

???+ warning "schedule: 0 0 0 * * *"
    This format differs from the traditional Unix/Linux crontab—it includes a seconds field as the first entry.

## Backup
Always refer to the official documentation for the most up-to-date and comprehensive information.  
<a href="https://cloudnative-pg.io/documentation/1.27/backup/" target="_blank">cloudnative-pg.io backup</a>  
<a href="https://cloudnative-pg.io/documentation/1.27/samples/#backups" target="_blank">cloudnative-pg.io backup samples</a>

## Restore
Always refer to the official documentation for the most up-to-date and comprehensive information.  
<a href="https://cloudnative-pg.io/documentation/1.27/recovery/" target="_blank">cloudnative-pg.io restore from backup</a>


## Rolling updates of the clusters
Always refer to the official documentation for the most up-to-date and comprehensive information.  
<a href="https://cloudnative-pg.io/documentation/1.27/rolling_update/" target="_blank">cloudnative-pg.io rolling updates</a>

## Kubectl plugin
You can install the kubectl plugin `cnpg` to manage your CloudnativePG clusters.  
See the official documentation:  
<a href="https://cloudnative-pg.io/documentation/1.27/kubectl-plugin/" target="_blank">cloudnative-pg.io kubectl plugin</a>  
```bash
tux@linux:~/git/containerplatform-docs$ kubectl cnpg --help
A plugin to manage your CloudNativePG clusters

Usage:
  kubectl cnpg [command]

Operator-level administration
  install      CloudNativePG installation-related commands

Troubleshooting
  logs         Logging utilities
  report       Report on the operator or a cluster for troubleshooting

Cluster administration
  destroy      Destroy the instance named CLUSTER-INSTANCE with the associated PVC
  fencing      Fencing related commands
  hibernate    Hibernation related commands
  maintenance  Sets or removes maintenance mode from clusters
  promote      Promote the instance named CLUSTER-INSTANCE to primary
  reload       Reload a cluster
  restart      Restart a cluster or a single instance in a cluster

Database administration
  backup       Request an on-demand backup for a PostgreSQL Cluster
  certificate  Create a client certificate to connect to PostgreSQL using TLS and Certificate authentication
  publication  Logical publication management commands
  snapshot     DEPRECATED (use `backup -m volumeSnapshot` instead)
  status       Get the status of a PostgreSQL cluster
  subscription Logical subscription management commands

Miscellaneous
  fio          Creates a fio deployment, pvc and configmap
  pgadmin4     Creates a pgAdmin deployment
  pgbench      Creates a pgbench job
  psql         Start a psql session targeting a CloudNativePG cluster

Additional Commands:
  completion   Generate the autocompletion script for the specified shell
  help         Help about any command
  version      Prints version, commit sha and date of the build

```
Really handy tool to have! I have used it to test the storage performance with the `fio` and `pgbench` commands.

## More Examples 
Cloudnative PG has a lot of great examples and yaml files on their website, for different use cases.  
<a href="https://cloudnative-pg.io/documentation/1.27/samples/" target="_blank">cloudnative-pg.io samples</a>