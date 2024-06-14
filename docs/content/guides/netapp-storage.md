# Net app Storage for OpenShift4

When using NetApp Trident with NFS ONTAP on OpenShift, several access modes are available for Persistent Volume Claims (
PVCs).
Understanding these access modes is essential for deploying applications with the appropriate storage configurations.
Here are the available access modes and their details:

### Access Modes for NFS ONTAP with Trident on OpenShift

1. **ReadWriteOnce (RWO)**:
    - **Description**: The volume can be mounted as read-write by a single node.
    - **Use Case**: Suitable for applications that require write access by only one pod or node at a time, such as
      databases.

2. **ReadOnlyMany (ROX)**:
    - **Description**: The volume can be mounted as read-only by many nodes.
    - **Use Case**: Ideal for scenarios where the data does not change and can be accessed by multiple pods or nodes,
      such as shared configuration files or static content.


3. **ReadWriteMany (RWX)**:
    - **Description**: The volume can be mounted as read-write by many nodes.
    - **Use Case**: Suitable for applications that need simultaneous read-write access from multiple pods or nodes,
      such as shared file storage, content management systems, or collaborative platforms.

### Creating a Persistent Volume Claim (PVC) with Access Modes

When creating a PVC to use with NFS ONTAP and Trident, specify the desired access mode in the PVC definition.
Choose one of the access modes based on your application's requirements.

Here are examples of PVC definitions for each access mode:

#### ReadWriteMany (RWX)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: example-pvc-rwx
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: netapp
  resources:
    requests:
      storage: 1Gi

```

#### ReadOnlyMany (ROX)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: example-pvc-rox
spec:
  accessModes:
    - ReadOnlyMany
  storageClassName: netapp
  resources:
    requests:
      storage: 1Gi

```

#### ReadWriteOnce (RWO)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: example-pvc-rwo
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: netapp
  resources:
    requests:
      storage: 1Gi

```

### Applying the PVC Definition

Save the YAML content to a file (e.g., `example-pvc-rwx.yaml`) and apply it to your OpenShift project:

```bash
oc apply -f example-pvc-rwx.yaml
```

### Create a Deployment with PVC Volume Mount

Next, create a Deployment YAML file that defines your application's deployment configuration.
Ensure that you specify the PVC as a volume mount in your container spec. Here’s an example Deployment YAML:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: example
  template:
    metadata:
      labels:
        app: example
    spec:
      containers:
        - name: example-app
          image: nginx:latest
          volumeMounts:
            - mountPath: "/data"
              name: data-volume
      volumes:
        - name: data-volume
          persistentVolumeClaim:
            claimName: example-pvc-rwx

```

Save this YAML to a file (e.g., example-deployment.yaml) and apply it to the project:

```bash
oc apply -f example-deployment.yaml
```
