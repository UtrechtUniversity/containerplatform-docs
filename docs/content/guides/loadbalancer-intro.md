## Introduction Citrix Netscaler

When you are running an application inside OpenShift, you need to provide a way for external users to access the applications from outside the OpenShift cluster.
Kubernetes provides an object called Ingress which allows you to define the rules for accessing the services with in the Kubernetes / OpenShift cluster.
At the University of Utrecht, we use Citrix Netscaler as Ingress / LoadBalancer.
NetScaler provides an implementation of the Kubernetes Ingress Controller to manage and route traffic into the OpenShift cluster.
The Citrix Netscaler (for now) provides load balancing at layer 7 only, so only HTTP(S) traffic is possible.
In production, the url of the LoadBalancer is:


| NAME | IP Address |
| ---- | ---------- |
| vpx-cl01.cp.its.uu.nl | 131.211.5.163 |

### Certificates

When you open an application to the outside world, you want it to be secure using a TLS certificate. The request of a certificate should be easy and automated. For that we use cert-manager.

### Cert-Manager

cert-manager is a powerful and extensible X.509 certificate controller for Kubernetes and OpenShift workloads.
It will obtain certificates from a variety of Issuers, both popular public Issuers as well as private Issuers, and ensure the certificates are valid and up-to-date, and will attempt to renew certificates at a configured time before expiry.
cert-manager is using the ACME protocol that automates interactions between Certificate Authorities (CAs) and their users' servers.

At the University we have several issuers that use the ACME protocol and can be used to create certificates:

| NAME |
| ---- |
| letsencrypt-staging-vpx |
| letsencrypt-vpx |
| harica |


When you are developing or testing your code, letsencrypt-staging-vpx can be used. Harica is available this should be the default for production.

### Create CNAME

To use the LoadBalancer, First you have to (or let someone) create a CNAME that points to the LoadBalancer (vpx-cl01.cp.its.uu.nl)

```code
dig +short app17.its.uu.nl
vpx-cl01.cp.its.uu.nl.
131.211.5.163
```

So here app17.its.uu.nl points to vpx-cl01.cp.its.uu.nl, which is the URL of the LoadBalancer.

### Termination Types

The loadbalancer can be setup using edge termination or passthrough. In edge termination, the traffic is encrypted from the browser to the loadbalancer. Traffic from the loadbalancer into the openshift
cluster is not encrypted. This is the easiest way to setup, because the application is not aware of any TLS certificates. Setting up TLS certificates on application pods is very application specific.

For an example using edge termination: [Loadbalancer edge termination](loadbalancer-edge.md)
For an example using passthrough: [Loadbalancer passthrough](loadbalancer-passthrough.md)

### Allowlist / Blacklist

Sometimes you want to allow or block access to your application for some IP addresses or CIDR.  
To set this up see: [Loadbalancer allowlist blacklist](loadbalancer-white-black-list.md)

### X-Forward-For

To enable the X-Forward-For header: [Loadbalancer x-forward-for](loadbalancer-xforwardfor.md)

### Configure an Ingress on the Netscaler using the GUI

The procedure to create / modify an ingress using the GUI: [Loadbalancer configure GUI](loadbalancer-ingress-gui.md)
