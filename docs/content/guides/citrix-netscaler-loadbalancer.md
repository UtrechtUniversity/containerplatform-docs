## Introduction Citrix Netscaler

When you are running an application inside OpenShift, you need to provide a way for external users to access the applications from outside the OpenShift cluster.  
Kubernetes provides an object called Ingress which allows you to define the rules for accessing the services with in the Kubernetes / OpenShift cluster.  
At the University of Utrecht, we use Citrix Netscaler as Ingress / LoadBalancer.  
NetScaler provides an implementation of the Kubernetes Ingress Controller to manage and route traffic into the OpenShift cluster.

### Cert Manager

cert-manager is a powerful and extensible X.509 certificate controller for Kubernetes and OpenShift workloads. 
It will obtain certificates from a variety of Issuers, both popular public Issuers as well as private Issuers, and ensure the certificates are valid and up-to-date, and will attempt to renew certificates at a configured time before expiry.
cert-manager is using the ACME protocol that automates interactions between Certificate Authorities (CAs) and their users' servers.

We have several cluster issues that use the ACME protocol and can be used to create certificates:

| NAME |
| ---- |
| letsencrypt-staging-vpx |
| letsencrypt-vpx |
| <s>sectigo</s> |
| harica |

Harica is not available yet but will be available in the near future and replaces Sectigo.  
When Harica is available, it should be used in production.  
letsencrypt-staging-vpx can be used for development purposes.  
letsencrypt-vpx for production until Harica is available.  
 
### Create CNAME

First you have to (or let someone) create a CNAME that points to the LoadBalancer (vpx-cl01.cp.its.uu.nl)

```code
dig +short app17.its.uu.nl
vpx-cl01.cp.its.uu.nl.
131.211.5.163
```

So here app17.its.uu.nl points to vpx-cl01.cp.its.uu.nl, which is the URL of the LoadBalancer.

### Example Use Citrix Netscaler with edge termination

In Edge termination, the traffic is encrypted from the browser to the LoadBalancer.  
Traffic from LoadBalancer into the cluster is not encrypted.  
In this example, the CNAME app17.its.uu.nl is used with an app name of app17.  
First we create a deployment with an nginx container:

#### 1. create deployment

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
#### 2. Create a service

Next we expose the deployment to create a service.

```code
oc expose deployment/app17 --name app17 --target-port=8080 --type=NodePort
```

We need to expose the deployment as type NodePort for the LoadBalancer.  
It is also possible to create the service using a yaml and not use oc expose (see the next example).

#### 3. Create ingress

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

- cert-manager.io/cluster-issuer: letsencrypt-vpx  
This annotation configures what issuer to use as shown in the table above.
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

#### 4. Check Certificate

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

### Example Use Citrix Netscaler with passthrough ingress

It is possible to create a so called end-to-end encryption. This is harder to setup and is very application specific.
When you create a passthrough ingress, the OpenShift pod mounts and uses the certificates.  
The application is aware of the certificates, which is not the case when edge termination is used.  
Here the nginx image is used. The nginx configuration should be modified too to tell nginx which certificates should be used.


#### 1. Create Nginx Configuration

```code
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-conf-app18
data:
  nginx.conf: |
    pid /tmp/nginx.pid;
    events {
    }
    http {
      server {
        listen 8080 ssl;

        root /usr/share/nginx/html;
        index index.html;

        server_name app18.its.uu.nl;
        ssl_certificate /etc/nginx-server-certs/tls.crt;
        ssl_certificate_key /etc/nginx-server-certs/tls.key;
      }
    }
```

This configmap holds the nginx configuration, that is later used by the pod.

#### 2. Create service

```code
apiVersion: v1
kind: Service
metadata:
  name: app18
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app.kubernetes.io/name: app18
  sessionAffinity: None
  type: NodePort
```

#### 3. Create Certificate

When using the LoadBalancer as passthrough ingress, we don't create a certificate with the ingress annotation, but we create the certificate ourselves.

```code
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: app18-tls
spec:
  dnsNames:
  - app18.its.uu.nl
  issuerRef:
    group: cert-manager.io
    kind: ClusterIssuer
    name: letsencrypt-vpx
  secretName: app18-tls
  usages:
  - digital signature
  - key encipherment
```

```code
$ oc get certificate app18-tls
NAME        READY   SECRET      AGE
app18-tls   True    app18-tls   33s
```

!!! note
    Sometimes when you create this certificate, READY stays False with an error message that app18-tls does not exist.  
    What usually helps then is delete the certificate and create it again.
    
#### 4. Create Deployment that uses the certificates in app18-tls

```code
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app18
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: app18
  replicas: 5
  template:
    metadata:
      labels:
        app.kubernetes.io/name: app18
    spec:
      containers:
      - name: my-nginx
        image: nginxinc/nginx-unprivileged
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: nginx-config-app18
          mountPath: /etc/nginx
          readOnly: true
        - name: nginx-server-certs
          mountPath: /etc/nginx-server-certs
          readOnly: true
      volumes:
      - name: nginx-config-app18
        configMap:
          name: nginx-conf-app18
      - name: nginx-server-certs
        secret:
          secretName: app18-tls
```

We have setup two volumes here, a volume with the configmap, that is mounted on /etc/nginx and a volume with the tls certificate that is mounted on /etc/nginx-server-certs.


```code
$ oc get deployment/app18
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
app18   5/5     5            5           75s
```

#### 5. Create ingress

```code
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    ingress.citrix.com/ssl-passthrough: "True"
    ingress.citrix.com/secure-backend: "True"
    ingress.citrix.com/insecure-termination: redirect
  name: app18
spec:
  ingressClassName: nsic-vpx
  rules:
  - host: app18.its.uu.nl
    http:
      paths:
      - backend:
          service:
            name: app18
            port:
              number: 8080
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - app18.its.uu.nl
    secretName: app18-tls
```

There are some annotations needed:  

- ingress.citrix.com/ssl-passthrough: "True"  
This enables SSL passthrough on the Ingress Netscaler
- ingress.citrix.com/insecure-termination: redirect  
This redirects insecure traffic to port 443.
- ingress.citrix.com/secure-backend: "True"
This tells the Netscaler we have TLS certificates in a secure backend.


#### 6. Check Certificate

```code
$ curl --silent  https://app18.its.uu.nl | grep Welcome
<title>Welcome to nginx!</title>
<h1>Welcome to nginx!</h1>
```

```code
$ openssl s_client -connect app18.its.uu.nl:443
Connecting to 131.211.5.163
CONNECTED(00000003)
depth=2 C=US, O=Internet Security Research Group, CN=ISRG Root X1
verify return:1
depth=1 C=US, O=Let's Encrypt, CN=R11
verify return:1
depth=0 CN=app18.its.uu.nl
verify return:1
---
Certificate chain
 0 s:CN=app18.its.uu.nl
   i:C=US, O=Let's Encrypt, CN=R11
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Jun  5 10:02:10 2025 GMT; NotAfter: Sep  3 10:02:09 2025 GMT
 1 s:C=US, O=Let's Encrypt, CN=R11
   i:C=US, O=Internet Security Research Group, CN=ISRG Root X1
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Mar 13 00:00:00 2024 GMT; NotAfter: Mar 12 23:59:59 2027 GMT
```

We can check if the certificate are actually mounted in the Pod(s):

```code
oc set volume deploy/app18
 app18
  configMap/nginx-conf-app18 as nginx-config-app18
    mounted at /etc/nginx
  secret/app18-tls as nginx-server-certs
    mounted at /etc/nginx-server-certs
```

This example is using nginx. For Apache or other applications, the location to mount the certificates and the configuration is very different.







