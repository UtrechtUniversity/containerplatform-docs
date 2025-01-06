## Single page webapp served from shared volume and exposed with ingress

This is a simple example singlepage webapp that starts with a **PersistentVolumeClaim** and an onetime **Job** that
copies the `index.html` from a git gist to the shared volume. The **Deployment** spawns 3 **Pods** with an init
container that waits until an `index.html` file is present.
After that an unpriviledged nginx container starts serving it. A service is created and exposed through an **Ingress**,
in case of Openshift it also creates a coupled **Route**. A **CronJob** is added to periodically copy again the
`index.html` for automatic updating purposes.
Let's begin!

### Preparation

Before applying the manifests be sure to login to the Kubernetes Openshift Cluster and create
a [docker secret](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/). \
ie.
`kubectl create secret docker-registry docker-cred --docker-server="docker.io" --docker-username=<your-uname> --docker-password=<your-pword> --docker-email=<your-uuemail>`

### The shared volume, the job, the deployment

In the Openshift web UI, press + on the upper right and import YAML (copy-paste). Alternatively,
`kubectl apply -f <filename/directory>` can be used.
First we create the **PersistentVolumeClaim**, then we create a onetime **Job** that mounts it under the directory
`/tmp/gist/` and downloads `index.html`into it.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-phoenix
  labels:
    app: phoenix
spec:
  storageClassName: netapp
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 100Mi
---
apiVersion: batch/v1
kind: Job
metadata:
  name: copiecurl-phoenix
  labels:
    app: phoenix
spec:
  template:
    spec:
      volumes:
      - name: storage-phoenix
        persistentVolumeClaim:
          claimName: pvc-phoenix
      imagePullSecrets:
      - name: docker-cred
      containers:
      - name: curl-phoenix
        image: docker.io/curlimages/curl
        volumeMounts:
        - name: storage-phoenix
          mountPath: /tmp/gist/
        command: ["/bin/sh"]
        args: ["-c", "curl https://gist.githubusercontent.com/gdamaskos/f1a8ee5cffa83f51fed45680c310c9ad/raw/index.html -o /tmp/gist/index.html;"]
      restartPolicy: Never
  backoffLimit: 4
```

In the meantime, the 3 **Pods** that are create by the **Deployment** are running their init containers which wait until
the `index.html` file is present. Then an unpriviledged nginx container starts serving it. \
Note that the containers' **volumeMount** as `readOnly: true`. Since there is no need to write to it simultaneously,
there is no need for a **StatefulSet**.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: server-phoenix
  labels:
    app: phoenix
spec:
  replicas: 3
  selector:
    matchLabels:
      app: phoenix
  progressDeadlineSeconds: 300
  minReadySeconds: 10
  template:
    metadata:
      labels:
        app: phoenix
    spec:
      volumes:
        - name: storage-phoenix
          persistentVolumeClaim:
            claimName: pvc-phoenix
      imagePullSecrets:
        - name: docker-cred
      initContainers:
        - name: init-wait4index
          volumeMounts:
            - name: storage-phoenix
              mountPath: /tmp
              readOnly: true
          image: busybox
          command: [ 'sh', '-c', "until [ -e /tmp/index.html ]; do sleep 1; done; echo index.html exists" ]
      containers:
        - name: nginx-unprivileged
          image: docker.io/nginxinc/nginx-unprivileged
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: storage-phoenix
              mountPath: /usr/share/nginx/html/
              readOnly: true
```

### The service, the ingress, the cronjob

A service is created and exposed through an **Ingress**, in case of Openshift it also creates a coupled **Route**. A *
*CronJob** is added to periodically copy again the `index.html` for automatic updating purposes.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: service-phoenix
  labels:
    app: phoenix
spec:
  type: ClusterIP
  selector:
    app: phoenix
  ports:
    - port: 8080
      protocol: TCP
      targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-phoenix
  labels:
    app: phoenix
  annotations:
    INGRESS.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt # or: sectigo
spec:
  ingressClassName: openshift-default
  rules:
    - host: <your-domain>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: service-phoenix
                port:
                  number: 8080
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: croncopiecurl-phoenix
  labels:
    app: phoenix
spec:
  schedule: "0 0 * * *" # run once a day at midnight
  jobTemplate:
    spec:
      template:
        spec:
          volumes:
            - name: storage-phoenix
              persistentVolumeClaim:
                claimName: pvc-phoenix
          imagePullSecrets:
            - name: docker-cred
          containers:
            - name: curl-phoenix
              image: docker.io/curlimages/curl
              command: [ "/bin/sh" ]
              args: [ "-c", "curl https://gist.githubusercontent.com/gdamaskos/f1a8ee5cffa83f51fed45680c310c9ad/raw/index.html -o /tmp/gist/index.html;" ]
              volumeMounts:
                - name: storage-phoenix
                  mountPath: /tmp/gist
          restartPolicy: Never
      backoffLimit: 4
```

To verify it worked: `kubectl get ingress` and then curl the returned URL ie. `curl phoenix.k8s.im.hum.uu.nl`.

### Cleanup

The resources can be deleted manually from the web UI or if there are YAML manifests:
`kubectl delete -f <filename/directory> --now`
If necessary the secret can be removed with a separate command.
