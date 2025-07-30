# Migration from haproxy load balancer to vpx load balancer
 This guide will help you migrate from the haproxy load balancer to the vpx load balancer.

## Example of the migration

- files you need to change:
  - `ingress.yaml`
  - `service.yaml`
- files you need to create (if you use whitelisting):
  - `allowlistip.yaml`

### Ingress, old configuration which is deprecated (in the near future)
> The haproxy.router.openshift.io/ip_whitelist annotation will be replaced by the api object rewritepolicy.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
    haproxy.router.openshift.io/ip_whitelist: 131.211.0.0/16 10.0.0.0/8 172.16.0.0/12
      145.107.64.0/18 145.107.128.0/19 145.136.128.0/19 45.83.234.187
  name: speeltuin-cdh-uu-nl
  namespace: gw-dev-systemteam-banana
spec:
  rules:
  - host: speeltuin.cdh.uu.nl
    http:
      paths:
      - backend:
          service:
            name: speeltuin-cdh-uu-nl
            port:
              number: 8923
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - speeltuin.cdh.uu.nl
    secretName: speeltuin-cdh-uu-nl-tls
```

### Ingress, new configuration which is the new way to do it
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-vpx # or letsencrypt-staging-vpx, for prd use harica
  name: speeltuin-cdh-uu-nl
  namespace: gw-dev-systemteam-banana
spec:
  rules:
  - host: speeltuin.cdh.uu.nl
    http:
      paths:
      - backend:
          service:
            name: speeltuin-cdh-uu-nl
            port:
              number: 8923
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - speeltuin.cdh.uu.nl
    secretName: speeltuin-cdh-uu-nl-tls
```

### Service, old configuration which is deprecated (in the near future)

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: speeltuin-cdh-uu-nl
  name: speeltuin-cdh-uu-nl
  namespace: gw-dev-systemteam-banana
spec:
  type: ClusterIP
  ports:
  - port: 8923
    protocol: TCP
    targetPort: 8923
  selector:
    app: speeltuin-cdh-uu-nl
```

### Service, new configuration
> ClusterIP --> NodePort

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: speeltuin-cdh-uu-nl
  name: speeltuin-cdh-uu-nl
  namespace: gw-dev-systemteam-banana
spec:
  type: NodePort
  ports:
  - port: 8923
    protocol: TCP
    targetPort: 8923
  selector:
    app: speeltuin-cdh-uu-nl
```

### RewritePolicy, new configuration which is the new way to do it
> See the guide [Loadbalancer-white-black-list](loadbalancer-white-black-list.md) for examples and more information.

```yaml
apiVersion: citrix.com/v1
kind: rewritepolicy
metadata:
  name: allowlistip
  namespace: gw-dev-systemteam-banana
  labels:
    app: speeltuin-cdh-uu-nl
spec:
  responder-policies:
  - responder-policy:
      drop: ""
      respond-criteria: '!client.ip.src.TYPECAST_text_t.equals_any("allowlistip")'
      comment: Allowlist certain IP addresses
    servicenames:
      - speeltuin-cdh-uu-nl
  patset:
  - name: allowlistip
    values:
      - 145.107.64.0/18 
      - 172.16.0.0/12
      - 131.211.0.0/16
      - 10.0.0.0/8
      - 145.107.128.0/19
      - 145.136.128.0/19
      - 45.83.234.187
```
