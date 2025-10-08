# CloudnativePG

We can't write better documentation about CloudnativePG than the CloudnativePG team itself. 
So we refer you to their documentation and code repository.

Find the guide at <a href="https://cloudnative-pg.io/documentation/1.27/" target="_blank">cloudnative-pg.io</a>  
Find the code at <a href="https://github.com/cloudnative-pg" target="_blank">GitHub cloudnative-pg</a>

# Specifics for our OpenShift Container Platform

Use storageClass: `thin-csi`  
Use postgresUID: `26`  
Use postgresGID: `26`  

## Backups possible with CloudnativePG on our platform
We support two types of backups for CloudnativePG:
### Volume snapshot for backups
Our storageclass `thin-csi` supports volume snapshots see the official docs: <a href="https://cloudnative-pg.io/documentation/1.27/appendixes/backup_volumesnapshot/#about-standard-volume-snapshots" target="_blank">snapshot feature</a>  
### S3 Object Storage for backups
prerequisites:
 - S3 bucket (contact our storageteam)
 - S3 credentials (access key id and secret access key)

You can use the barman plugin to back up your cluster (databases) to our S3 object storage.
If you want to use the barman plugin, you need to create a secret with your S3 credentials, and an ObjectStore object. See the example below.

## Example of a minimal CloudnativePG cluster

```yaml
---
kind: Cluster
apiVersion: postgresql.cnpg.io/v1
metadata:
  name: cluster-example
  namespace: example-namespace
spec:
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

## Example of a minimal CloudnativePG objectstore setup

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

## Backup and Restore
Always refer to the official documentation for the most up-to-date and comprehensive information.
<a href="https://cloudnative-pg.io/documentation/1.27/operator_capability_levels/#point-in-time-recovery-pitr-from-a-backup" target="_blank">cloudnative-pg.io backup & restore</a>  
PostgreSQL Backups

CloudNativePG provides a pluggable interface (CNPG-I) for managing application-level backups using PostgreSQL’s native physical backup mechanisms—namely base backups and continuous WAL archiving. This design enables flexibility and extensibility while ensuring consistency and performance.

The CloudNativePG Community officially supports the Barman Cloud Plugin, which enables continuous physical backups to object stores, along with full and Point-In-Time Recovery (PITR) capabilities.

In addition to CNPG-I plugins, CloudNativePG also natively supports backups using Kubernetes volume snapshots, when supported by the underlying storage class and CSI driver.

You can initiate base backups in two ways:

    On-demand, using the Backup custom resource
    Scheduled, using the ScheduledBackup custom resource, with a cron-like schedule format

Volume snapshots leverage the Kubernetes API and are particularly effective for very large databases (VLDBs) due to their speed and storage efficiency.

Both volume snapshots and CNPG-I-based backups support:

    Hot backups: Taken while PostgreSQL is running, ensuring minimal disruption.
    Cold backups: Performed by temporarily stopping PostgreSQL to ensure a fully consistent snapshot, when required.

Backups from a standby

The operator supports offloading base backups onto a standby without impacting the RPO of the database. This allows resources to be preserved on the primary, in particular I/O, for standard database operations.
Full restore from a backup

The operator enables you to bootstrap a new cluster (with its settings) starting from an existing and accessible backup, either on a volume snapshot, or in an object store, or via a plugin.

Once the bootstrap process is completed, the operator initiates the instance in recovery mode. It replays all available WAL files from the specified archive, exiting recovery and starting as a primary. Subsequently, the operator clones the requested number of standby instances from the primary. CloudNativePG supports parallel WAL fetching from the archive.
Point-in-time recovery (PITR) from a backup

The operator enables you to create a new PostgreSQL cluster by recovering an existing backup to a specific point in time, defined with a timestamp, a label, or a transaction ID. This capability is built on top of the full restore one and supports all the options available in PostgreSQL for PITR.
Zero-Data-Loss Clusters Through Synchronous Replication

Achieve zero data loss (RPO=0) in your local high-availability CloudNativePG cluster with support for both quorum-based and priority-based synchronous replication. The operator offers a flexible way to define the number of expected synchronous standby replicas available at any time, and allows customization of the synchronous_standby_names option as needed.
Replica clusters

Establish a robust cross-Kubernetes cluster topology for PostgreSQL clusters, harnessing the power of native streaming and cascading replication. With the replica option, you can configure an autonomous cluster to consistently replicate data from another PostgreSQL source of the same major version. This source can be located anywhere, provided you have access to a WAL archive for fetching WAL files or a direct streaming connection via TLS between the two endpoints.

Notably, the source PostgreSQL instance can exist outside the Kubernetes environment, whether in a physical or virtual setting.

Replica clusters can be instantiated through various methods, including volume snapshots, a recovery object store (using the Barman Cloud backup format), or streaming using pg_basebackup. Both WAL file shipping and WAL streaming are supported. The deployment of replica clusters significantly elevates the business continuity posture of PostgreSQL databases within Kubernetes, extending across multiple data centers and facilitating hybrid and multi-cloud setups. (While anticipating Kubernetes federation native capabilities, manual switchover across data centers remains necessary.)

Additionally, the flexibility extends to creating delayed replica clusters intentionally lagging behind the primary cluster. This intentional lag aims to minimize the Recovery Time Objective (RTO) in the event of unintended errors, such as incorrect DELETE or UPDATE SQL operations.### More execllent examples at their website

## Examples 
Cloudnative PG has a lot of great examples and yaml files on their website, for different use cases.
<a href="https://cloudnative-pg.io/documentation/1.27/samples/" target="_blank">cloudnative-pg.io samples</a>