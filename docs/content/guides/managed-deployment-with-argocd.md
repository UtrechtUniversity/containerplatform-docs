# How to manage your deployment with ArgoCD

## Prerequisites
- [x] Code repository with your application `yaml` files (contact the ITS Linux team to add your repository to ArgoCD)
- [x] An AppProject (provided by the ITS Linux team)

### Code repository
ArgoCD manages the deployment of your application, based on the presence of the deployment files in your (configured) repository.  
Typically, a deployment repo has files like:  

- `deployment.yaml`  
- `service.yaml`  
- `ingress.yaml`  

We've created an example Nginx deployment for inspiration which can be found here:  
[example argo deployment](https://git.its.uu.nl/ITS/example-argocd-deployment)

### AppProject for ArgoCD
An AppProject can be requested via a Topdesk call. The information needed for ITS Linux to create this `AppProject` is the following:  

- In which namespace do you want to deploy your application?  
- What is the source git repository (.git url)?  
- Which OpenShift group is allowed to access the project (this is the group that has access to the namespace)?  

### Private or internal Git repository

If your Git repository is private or internal, ArgoCD requires credentials to access it. The recommended approach is to use a GitHub App.  
Once the GitHub App has been configured, ArgoCD can access all repositories that the GitHub App has permission to read.

#### Create a GitHub App

1. Navigate to your GitHub organization.
2. Go to **Settings → Developer settings → GitHub Apps**.
3. Click **New GitHub App**.

Configure the GitHub App with at least the following settings:

##### Repository permissions

| Permission | Access |
|------------|--------|
| Contents | Read-only |
| Metadata | Read-only |

##### Repository access

Select one of the following:

- **All repositories** (recommended)
- **Only select repositories**

If you choose **Only select repositories**, make sure the repositories that ArgoCD should deploy from are included.

#### Generate a private key

After creating and installing the GitHub App:

1. Open the GitHub App.
2. Select **Private keys**.
3. Click **Generate a private key**.
4. Download the generated `.pem` file.

You will need the following values:

- GitHub App ID
- GitHub App Installation ID
- GitHub App Private Key

#### Create a Secret

Create a Kubernetes Secret containing the GitHub App credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: github-app-creds
  namespace: openshift-gitops
  labels:
    argocd.argoproj.io/secret-type: repo-creds
type: Opaque
stringData:
  githubAppID: "<GitHub App ID>"
  githubAppInstallationID: "<Installation ID>"
  githubAppPrivateKey: |
    -----BEGIN RSA PRIVATE KEY-----
    ...
    -----END RSA PRIVATE KEY-----
  url: https://github.com/<organization>
  insecure: "true"
  type: git
  name: github
```

#### Seal the Secret

Do **not** commit the unencrypted Secret to Git.
Seal the Secret using your organization's Sealed Secrets process. The resulting `SealedSecret` can safely be committed to Git,   
as only the Sealed Secrets controller running in OpenShift can decrypt it.
[sealed-secrets](https://docs.cp.its.uu.nl/content/guides/seal-your-secrets/)

#### Send the sealed secret to the ITS Linux team
They can add it to the `openshift-gitops` namespace, so argoCD can use it to access your private Git repository.

## Create <application>.yaml application
The `application.yaml` file is the file that ArgoCD uses to deploy your application. The file contains information about the application itself.
The file is typically located in the `argocd` folder of your git repository. The file contains information about the application itself. 
The file should look similar like this:
```yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <name of your application>
  namespace: <faculty>-cd # i.e. 'gw-cd'. Each faculty has their own cd namespace, this namespace is managed by the ITS Linux team
  labels:
    name: <name of the application>
spec:
  project: <faculty> # i.e. 'gw' (based on the namespace)
  source:
    repoURL: <exact git url> # i.e. 'https://git.its.uu.nl/ITS/example-argocd-deployment.git'
    targetRevision: main # branch name, typically `main`
    path: . # path to the folder where the deployment files are located (in the case of the example-argocd-deployment repo this is the location of the `kustomization.yaml` file)
  destination:
    server: https://kubernetes.default.svc
    namespace: <namespace> # this is the namespace where the application is deployed
  info:
    - name: 'Owner: '
      value: 'ITS Linux' # some basic information about the owner of the application
  syncPolicy:
    automated:
      prune: false
      selfHeal: true
      allowEmpty: false
  revisionHistoryLimit: 10
```

## Deploy the application
First login to the [ArgoCD web UI](https://openshift-gitops-server-openshift-gitops.apps.cl01.cp.its.uu.nl/) (login with your SolisID).

Now it's time to "apply" the application file we've created above.
To do so make sure that you're logged into the OpenShift CLI (`oc login --web https://api.cl01.cp.its.uu.nl:6443`)

Now run the following command:

`$ kubectl apply -f argocd/<name-of-the-application>.yaml`

This will create the application in ArgoCD, and it will start syncing the application with the git repository.

Refer to the web UI for the status of the application. If everything is correct, you should see a green checkmark for your application.
