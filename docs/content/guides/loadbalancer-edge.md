## Example Use Citrix Netscaler with edge termination

In Edge termination, the traffic is encrypted from the browser to the LoadBalancer.  
Traffic from LoadBalancer into the cluster is not encrypted.  
In this example, the CNAME app17.its.uu.nl is used with an app name of app17.  
First we create a deployment with an nginx container:

### 1. create deployment

```code
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app17
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: app17
  replicas: 1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: app17
    spec:
      containers:
      - name: my-nginx
        image: nginxinc/nginx-unprivileged
        ports:
        - containerPort: 8080
```
### 2. Create a service

Next we expose the deployment to create a service.

```code
oc expose deployment/app17 --name app17 --target-port=8080 --type=NodePort
```

We need to expose the deployment as type NodePort for the LoadBalancer.  
It is also possible to create the service using a yaml and not use oc expose.

### 3. Create ingress

Next we create the ingress. 

```code
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    acme.cert-manager.io/http01-edit-in-place: "true"
    cert-manager.io/cluster-issuer: letsencrypt-vpx
    ingress.citrix.com/insecure-termination: redirect
  name: app17
spec:
  ingressClassName: nsic-vpx
  rules:
  - host: app17.its.uu.nl
    http:
      paths:
      - backend:
          service:
            name: app17
            port:
              number: 8080
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - app17.its.uu.nl
    secretName: app17-tls
```

There are some annotations needed:  

- ingressClassName: nsic-vpx  
This makes you use the loadbalancer.
- cert-manager.io/cluster-issuer: letsencrypt-vpx  
This annotation configures what issuer to use.
- ingress.citrix.com/insecure-termination: redirect  
This redirects insecure traffic (port 80) to port 443.
- acme.cert-manager.io/http01-edit-in-place: "true"  
This is needed when insecure-termination is set to redirect.
- app17-tls  
This is the secret that will hold the certificate created by cert-manager.

When this Ingress yaml file is applied, you can see an acme pod is started that is used by cert-manager to set the certificate.
When it disappears, the certificate should be ready:

```code
oc get certificate app17-tls
NAME        READY   SECRET      AGE
app17-tls   True    app17-tls   55s
```

### 4. Check Certificate

Now we can check if the application can be reached.

```code
curl --silent https://app17.its.uu.nl  | grep Welcome
<title>Welcome to nginx!</title>
<h1>Welcome to nginx!</h1>
```

And we can check certificate information:

```code
openssl s_client -connect app17.its.uu.nl:443
Connecting to 131.211.5.163
CONNECTED(00000003)
depth=2 C=US, O=Internet Security Research Group, CN=ISRG Root X1
verify return:1
depth=1 C=US, O=Let's Encrypt, CN=R11
verify return:1
depth=0 CN=app17.its.uu.nl
verify return:1
---
Certificate chain
 0 s:CN=app17.its.uu.nl
   i:C=US, O=Let's Encrypt, CN=R11
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Jun  5 09:24:50 2025 GMT; NotAfter: Sep  3 09:24:49 2025 GMT
 1 s:C=US, O=Let's Encrypt, CN=R11
   i:C=US, O=Internet Security Research Group, CN=ISRG Root X1
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Mar 13 00:00:00 2024 GMT; NotAfter: Mar 12 23:59:59 2027 GMT
```

app17 now has a certificate terminated at the LoadBalancer. As mentioned before, the traffic between the load balancer and OpenShift is not encrypted.
