# Deploy a sample app on openshift4
To set up a sample app on OpenShift and expose it using Ingress, you can follow these steps:

1. **Deploy the Sample App**:
   For this example, let's deploy a simple web application. You can use a Docker image from Docker Hub or build your own. Here's a simple YAML for deploying a sample web application:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: sample-app
        image: your-sample-app-image:tag
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app
spec:
  selector:
    app: sample-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
---
```

Replace `your-sample-app-image:tag` with the Docker image you want to use.

Apply the YAML:

```bash
oc apply -f sample-app.yaml
```

2. **Create an Ingress Resource**:
   Define an Ingress resource to expose your application externally. Here's an example YAML for Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sample-ingress
  annotations:
     cert-manager.io/cluster-issuer: letsencrypt
spec:
  ingressClassName: openshift-default
  rules:
  - host: example.com  # Replace with your desired hostname
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sample-app
            port:
              number: 80
```

Replace `example.com` with your desired hostname. For this hostname, a TLS certificate will be created via cert-manager.

Apply the YAML:

```bash
oc apply -f sample-ingress.yaml
```

3. **Access the Sample App**:
   Once the Ingress resource is created and configured, you can access your sample app using the specified hostname (`example.com` in this example). Ensure that your DNS is configured to resolve the hostname to your OpenShift cluster's Ingress controller.

4. **Verify Ingress Configuration**:
   You can verify that the Ingress configuration is correct by checking the status of the Ingress resource:

```bash
oc get ingress sample-ingress
```

This should display details about your Ingress resource, including its status and any associated rules.

That's it! Your sample app should now be deployed and exposed using Ingress on OpenShift.
