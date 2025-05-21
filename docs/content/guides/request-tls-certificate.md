# Request a managed TLS certificate for your application

???+ info "New clusterissuer Harica & new loadbalancers in front of the cluster"
    We are in the process of adding a new clusterissuer (Harica) and new loadbalancers in front of the cluster. 
    This will allow you to use the Harica certificate authority for TLS certificates. The new loadbalancers will 
    also provide better performance and reliability for your applications. But there will be a change of ingressclass.
    We will keep you updated on the progress of this work.

To request a TLS certificate for your application, you can use cert-manager, which is a Kubernetes add-on that automates the management and issuance of TLS certificates. Cert-manager can be used to request certificates from Let's Encrypt and other certificate authorities. Currently, we only support Let's Encrypt on the OpenShift cluster. 
> A big plus using cert-manager is, that cert-manager manages the certificate, meaning that cert-manager makes sure your certificate is replaced before it expires. No manual interaction is needed!
## Create an Ingress Resource
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
  tls:
  - hosts:
    - energygame.geo.uu.nl
    secretName: hello-world-ingress-tls # Replace with your desired secret name (you don't need to make it in advance, it will be made for you)
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
oc apply -f ingress.yaml
```

That's it! Your ingress will be applied and cert-manager will automatically request a TLS certificate for your application.
