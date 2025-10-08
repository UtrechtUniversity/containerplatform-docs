# CloudnativePG

We can't write better documentation about CloudnativePG than the CloudnativePG team itself. 
So we refer you to their documentation and code repository.

Find the guide at <a href="https://cloudnative-pg.io/documentation/1.27/" target="_blank">cloudnative-pg.io</a>  
Find the code at <a href="https://github.com/cloudnative-pg" target="_blank">GitHub cloudnative-pg</a>

## Specifics for our OpenShift Container Platform

Use storageClass: `thin-csi`  
Use postgresUID: `26`  
Use postgresGID: `26`  
Use endpointURL: `https://s3.uu.nl` for S3 object storage  

### Backup possibilities with CloudnativePG on our platform
We support two types of backups for CloudnativePG:
#### Volume snapshot for backups
Our storageclass `thin-csi` supports volume snapshots, on how to see the official docs: <a href="https://cloudnative-pg.io/documentation/1.27/appendixes/backup_volumesnapshot/#about-standard-volume-snapshots" target="_blank">snapshot feature</a>  
#### S3 Object Storage for backups
prerequisites:
 - S3 bucket (contact our storageteam)
 - S3 credentials (access key id and secret access key)

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

## More Examples 
Cloudnative PG has a lot of great examples and yaml files on their website, for different use cases.  
<a href="https://cloudnative-pg.io/documentation/1.27/samples/" target="_blank">cloudnative-pg.io samples</a>