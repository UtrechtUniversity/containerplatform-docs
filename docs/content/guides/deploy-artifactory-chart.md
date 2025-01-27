# Deploy Artifactory-oss with PostgreSql using Helm chart

To set up Artifactory-oss and the PostgreSql database on Open Shift 4 using Helm3 you can follow these steps:

1. **Add JFrog Helm repository**

Add the JFrog Helm repo to your repo list.
```bash
helm repo add jfrog https://charts.jfrog.io
helm repo update
```

2. **Create key secrets**

As described [here](https://jfrog.com/help/r/jfrog-installation-setup-documentation/install-artifactory-single-node-on-openshift) we start by creating secrets for the Master key and Join key
```bash
# Create master key
export MASTER_KEY=$(openssl rand -hex 32)
echo ${MASTER_KEY}
 
# Create a secret containing the key. The key in the secret must be named master-key
kubectl create secret generic my-masterkey-secret --from-literal=master-key=${MASTER_KEY}
```

```bash
# Create join key
export JOIN_KEY=$(openssl rand -hex 32)
echo ${JOIN_KEY}
 
# Create a secret containing the key. The key in the secret must be named join-key
kubectl create secret generic my-joinkey-secret --from-literal=join-key=${JOIN_KEY}
```

3. **Create SA with special permissions**

Ask the Linux team to create a rule that allows a special service account to run with UID/GID 99. In this case that SA is `postgresql`. Then create that service account:
```bash
oc create sa postgresql
```

4. **Create values.yaml**

Create a values.yaml file in which you:
- specify the previously created SA (`postgresql`)
- specify the hostname (In this case, the host is set to `artifactory-bios-prd-cci.apps.cl01.cp.its.uu.nl` because the chart is deployed in the .`bios-prd-cci.apps.cl01.cp.its.uu.nl` namespace)
- use the previously defined secrets `my-masterkey-secret` and `my-joinkey-secret` are used.
- set `securityContext.fsGroup` and `containerSecurityContext.runAsUser` set to `99`. (The UID/GID given by the Linux team)
```yaml
---
artifactory:
  containerSecurityContext:
    enabled: false

  artifactory:
    masterKeySecretName: my-masterkey-secret
    joinKeySecretName: my-joinkey-secret
    podSecurityContext:
      enabled: false

  ingress:
    enabled: true
    hosts:
      - artifactory-bios-prd-cci.apps.cl01.cp.its.uu.nl
    tls:
      - termination: edge
      - insecureEdgeTerminationPolicy: Redirect

  nginx:
    enabled: false

  postgresql:
    serviceAccount:
      enabled: true
      name: postgresql
    volumePermissions:
      enabled: false
    securityContext:
      fsGroup: 99
    containerSecurityContext:
      runAsUser: 99
    postgresqlPassword: "specify your own password"
    persistence:
      size: 40Gi

```

5. **Deploy the Helm chart**

Deploy the Helm chart, here the Helm release is named `artifactory-oss` and the chart is pulled from the JFrog repository.
```bash
helm install artifactory-oss jfrog/artifactory-oss -f values.yaml
```
If you want to upgrade an existing Helm deployment, use `helm upgrade`:
```bash
helm upgrade artifactory-oss jfrog/artifactory-oss -f values.yaml
```
.
