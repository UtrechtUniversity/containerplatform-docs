Making your new or updated software application available for use by end-users can be done several different ways in Kubernetes / OpenShift. This can be done for example by:  

* Editing yaml files and deploy them using the GUI or CLI
* Helm Charts
* Operators
* CI/CD pipelines, such as GitLab / GitHub / OpenShift Pipelines
* GitOps tools like ArgoCD.
* Ansible

In the Deployments section are some examples given  
  
To deploy a sample application using yaml files: [Sample Application](deploy-a-sample-app.md)  
To deploy wordpress using yaml files: [Wordpress](deploy-a-sample-app.md)  

When you deploy using CI/CD tools like GitLab / GitHub, you need a service account to access the OpenShift cluster. This is explained here:  
[Deploy with ServiceAccount](deploy-using-a-serviceaccount.md)  

With Ansible / Ansible Application Platform it is also possible to deploy to OpenShift: [Ansible](deployment-with-ansible.md)  

An example of deploying Artifactory using a Helm Chart: [Helm Chart Example](deploy-artifactory-chart.md)
