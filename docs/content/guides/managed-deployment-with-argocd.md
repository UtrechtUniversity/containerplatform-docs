# How to manage your deployment with ArgoCD

## Prerequisites
- Code repository with your application yaml files
- An AppProject (provided by the ITS Linux team)

### Code repository
ArgoCD manages the deployment of your application, based on the presence of the deployment files in your (configured) repository.
Typically a deployment repo has files like:
- `deployment.yaml`
- `service.yaml`
- `ingress.yaml`

We've created an example Nginx deployment for inspiration which can be found here: https://git.its.uu.nl/ITS/example-argocd-deployment

### AppProject for ArgoCD
An AppProject can be requested via a Topdesk call. The information needed for ITS Linux to create this appproject is the following:
- In which namespace do you want to deploy your application?
- What is the source git repository (.git url)?
- Which OpenShift group is allowed to access the project (this is the group which has access in the namespace)?

## Create <application>.yaml application
The `application.yaml` file is the file that ArgoCD uses to deploy your application. The file contains information about the application itself.
The file is typically located in the argocd folder of your git repository. The file contains information about the application itself. 
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
First login to the ArgoCD web UI: https://openshift-gitops-server-openshift-gitops.apps.cl01.cp.its.uu.nl/ (login with your SolisID).

Now it's time to "apply" the application file we've created above.
To do so make sure that you're logged into the OpenShift CLI (`oc login --web https://api.cl01.cp.its.uu.nl:6443`)

Now run the following command:

`$ kubectl apply -f argocd/<name-of-the-application>.yaml`

This will create the application in ArgoCD and it will start syncing the application with the git repository.

Refer to the web UI for the status of the application. If everything is correct you should see a green checkmark for your application.
