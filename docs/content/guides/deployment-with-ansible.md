## This is an example guide to deploy to OpenShift using Ansible with a Service Account Token

## Prerequisites
- You need to have an account and project on the Container Platform.
- You need to have the OpenShift client tools installed. (only if you need to create a token)
- You need to be have enough rights to deploy to your own project (setup by a key user)

## Install requirements

For these deployments, **plain** Ansible is used, so not the Ansible Automation Platform.  
That platform used is Fedora, but these packages should be available on Ubuntu too.  
First install Ansible and the Kubernetes packages for Python.

```bash
$ sudo dnf install ansible python3-kubernetes -y
...
Running transaction
  Preparing        :                                                                                                                                                                                                                    1/1 
  Installing       : python3-oauthlib-3.2.2-3.fc40.noarch                                                                                                                                                                               1/9 
  Installing       : python3-requests-oauthlib-1.3.1-8.fc40.noarch                                                                                                                                                                      2/9 
  Installing       : python3-websocket-client-1.3.3-7.fc40.noarch                                                                                                                                                                       3/9 
  Installing       : python3-rsa-4.9-5.fc40.noarch                                                                                                                                                                                      4/9 
  Installing       : python3-pyasn1-modules-0.5.1-3.fc40.noarch                                                                                                                                                                         5/9 
  Installing       : python3-cachetools-5.3.2-3.fc40.noarch                                                                                                                                                                             6/9 
  Installing       : python3-google-auth-1:2.34.0-1.fc40.noarch                                                                                                                                                                         7/9 
  Installing       : python3-kubernetes-1:30.1.0-1.fc40.noarch                                                                                                                                                                          8/9 
  Installing       : ansible-9.10.0-1.fc40.noarch                                                                                                                                                                                       9/9 
  Running scriptlet: ansible-9.10.0-1.fc40.noarch                                                                                                                                                                                       9/9 

Installed:
  ansible-9.10.0-1.fc40.noarch                   python3-cachetools-5.3.2-3.fc40.noarch            python3-google-auth-1:2.34.0-1.fc40.noarch     python3-kubernetes-1:30.1.0-1.fc40.noarch        python3-oauthlib-3.2.2-3.fc40.noarch    
  python3-pyasn1-modules-0.5.1-3.fc40.noarch     python3-requests-oauthlib-1.3.1-8.fc40.noarch     python3-rsa-4.9-5.fc40.noarch                  python3-websocket-client-1.3.3-7.fc40.noarch    

Complete!
```
ansible-9.10.0 already has the collection kubernetes.core.k8s installed by default.  
if it is not working, you can always install it from ansible galaxy.
```bash
$ ansible-galaxy collection install kubernetes.core 
Starting galaxy collection install process
Nothing to do. All requested collections are already installed. If you want to reinstall them, consider using `--force`.
```
## Setup Service Account / Token / Project

In this guide, it is assumed a service account with enough permission and a projet is already available, like this steps here:  
[deploy-using-a-serviceaccount](https://docs.cp.its.uu.nl/content/guides/deploy-using-a-serviceaccount/)

First an example project is created:

```bash
$ oc new-project ansible-deployment
Now using project "ansible-deployment" on server "https://api.cl01.cp-acc.its.uu.nl:6443".
```

Then a service account with a rolebinding
```bash
$ oc project ansible-deployment
Already on project "ansible-deployment" on server "https://api.cl01.cp-acc.its.uu.nl:6443".

$ oc create sa ansible-sa
serviceaccount/ansible-sa created
```

Then create a token
```
$ oc create token ansible-sa
eyJhbGciOiJSUzI1NiIsImtpZCI6IjQtX1c4bzMtTENtLS0zNExKel9ZeFFPZHg5UmJMQ1A1U3R2MFBnVFF1RWcifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjIl0sImV4cCI6MTcyNjg0MDM4MiwiaWF0IjoxNzI2ODM2NzgyLCJpc3MiOiJodHRwczovL2t1YmVybmV0ZXMuZGVmYXVsdC5zdmMiLCJrdWJlcm5ldGVzLmlvIjp7Im5hbWVzcGFjZSI6ImFuc2libGUtZGVwbG95bWVudCIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJhbnNpYmxlLXNhIiwidWlkIjoiMWJkNWYxYTYtMDU5Ni00MDkzLWI5MDgtMmEyOTA3NTI0MTY3In19LCJuYmYiOjE3MjY4MzY3ODIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDphbnNpYmxlLWRlcGxveW1lbnQ6YW5zaWJsZS1zYSJ9.jmE1BdXW8UcjKa4-hYuas4TALoNyQzgOsu0zDXz69j_uLQd8n0dpUs3QxpuqWEHkEYREo7TbRkV_-qbWXV5FM75Mgt1mYgGMogpLZgWzbilj2wnblrHacdibSQNBVMTfmpE4ebajXw2Vju-zj6dapwouVCGqUnCTAchwXQlpwkf1Zg4-BLMrg-7MLQ7kpb9hgLqoFoUFiP4z-Odg8k8cynXabKm1hVtuX3mcF47PAKeXrpJQkuogBTnnJodwAqVbnjZhCbBlTw7Oa2csM1ErE9n12o_M21Ex4RFKDhyw7HO7ra3ynwDURj8mqbKb0nvXi2H9LfH_8lPEEAA8x6jmfVk3e9ow6I6p8ervj_XxTxD1nQe03chaXa15LozkFTxf9eP278Iqs8s2JwZYggpweZwtZhL0oNcIhCG4aPqkTICJeq3qzWq569ektUQ5FZmqNVNAUvaNCGWJglQuoLy4fBaQ-3ur2xZnhJYYC60re3qlSo_LV0tDQ_qzxVxFlgv1ttjtTnrmQiPWAPMwsKQuLgiuGAxfRlF9z1_B9Rm4s-0LIh7JX1O9N5ZM63DdELNubC01vlcY_4IHpr1gagRcw8AyDtPKpul_aNRmVNRHkdMK7nWFXyR6F7VrgLuKXP9IqW6kE-rrdUcp5YeMoN8pPLKDUl-lsA9FsKoeOy694UA
```
This token should be kept secret, but here it is just shown as example.  
To use this token, it should be kept in a Vault / GitHub / GitLab secret.  

Create a rolebinding
```
$ oc policy add-role-to-user edit -z ansible-sa
clusterrole.rbac.authorization.k8s.io/edit added: "ansible-sa"
```

## Setup Ansible
First store the token in a vault. 

```bash
$ ansible-vault create vault.yaml
New Vault password: 
Confirm New Vault password: 
```
When running these command an editor will open, paste there your token like this:  
token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjQtX1c4b....

Then create an example playbook like this:
```bash
$ vim deploy-to-openshift.yaml
- name: create a Deployment
  hosts: localhost
  tasks:
    - name: import vars file
      ansible.builtin.include_vars:
        file: vault.yaml

    - name: create deployment
      kubernetes.core.k8s:
        namespace: ansible-deployment        # CHANGE WITH YOUR PROJECT / NAMESPACE
        name: testing
        api_version: v1
        api_key: "{{ token }}"
        state: present
        src: "./deployment.yaml"            # This file should be created
```
The create deployment task loads a deployment.yaml to include in the playbook.
The contents are:
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: apache
  name: apache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
      - image: registry.access.redhat.com/rhscl/httpd-24-rhel7
        name: apache24
```
The deploy-to-openshift playbook loads the ansible vault.yaml.  
This file is encrypted, so it should some how know the password.
You can use a vault password file for this or let ansible ask for it.

## Deploying to OpenShift
Now let's test if it works
```bash
$ ansible-playbook deploy-to-openshift.yaml --ask-vault-pass 
Vault password: 
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'

PLAY [create a Deployment] *****************************************************************************************************************************************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************************************************************************************************************************
ok: [localhost]

TASK [import vars file] ********************************************************************************************************************************************************************************************************************
ok: [localhost]

TASK [create deployment] *******************************************************************************************************************************************************************************************************************
changed: [localhost]

PLAY RECAP *********************************************************************************************************************************************************************************************************************************
localhost                  : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Now test if the pods are running:
```
$ oc get deployment -n ansible-deployment
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
apache   1/1     1            1           111s
$ oc get pods -n ansible-deployment
NAME                      READY   STATUS    RESTARTS   AGE
apache-64dc8cb5ff-7nd97   1/1     Running   0          116s
```
A lot more cool stuff can be done with kubernetes.core.  
Have a look at the documentation: [kubernetes.core documentation](https://github.com/ansible-collections/kubernetes.core)

