# wordpress-example-app
How to deploy an wordpress app on openshift running in unpriviliged containers

## Steps

0. ***Have a dns entry for your site***  
   Create a netwerk dns change in topdesk to apply for your dns name.  
   e.g. ```wp-example.its.uu.nl```


1. **Clone this repo**  
   ```git clone https://github.com/UtrechtUniversity/wordpress-example-app```
2. **Replace the <your-....> with your own data in the yaml files below**
   - [x] mariadb-secret.yaml
   - [x] wordpress-cm.yaml
   - [x] wordpress-ingress.yaml
   - [x] wordpress-secret.yaml
   
   e.g.\
   ```wordpress-email: <your-email>``` with ```wordpress-email: thisismyemail@email.com```
3. **Run the script wordpress-app.sh or oc command**  
   ```bash wordpress-app.sh```

   ```oc apply -f .```  
   FYI. This could lead to a race condition, that is why I made the above script. So the correct order of resource creation is applied.

4. **Login to your admin site**  
   Go to the url you set in the ingress file, and append /admin to the url.  

   e.g [wp-example.its.uu.nl/admin](https://wp-example.its.uu.nl/admin)  
   Login with the credential you have set.

### Why We Use Bitnami Unprivileged Containers?

1. **Security Compliance:**
   OpenShift uses Security Context Constraints (SCCs) to define permissions and access controls for pods. By default, it restricts the use of root user to minimize the risk of privilege escalation attacks. Bitnami unprivileged containers are designed to comply with these constraints, ensuring smooth deployment and operation.

2. **Reduced Attack Surface:**
   Running containers as non-root reduces the attack surface, limiting the potential damage that can be done if a container is compromised. It prevents attackers from gaining elevated privileges on the host system.

3. **Best Practices Alignment:**
   Following best practices in container security, such as running applications as non-root, is essential for modern cloud-native applications. Bitnami unprivileged containers are built with these best practices in mind.

4. **Ease of Use:**
   Bitnami unprivileged containers come pre-configured to run as non-root users. This simplifies the process of deploying applications on OpenShift, as there is no need for additional configuration to drop privileges.

