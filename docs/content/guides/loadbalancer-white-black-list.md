## Allowlisting or blocklisting IP addresses

Sometimes you might want to allow only specific ip address ranges to access your application or maybe blacklist specific IP addresses. The Netscaler / loadbalancer has rewrite or responder policies so you can allowlist or blocklist the IP addresses/CIDR using which users can access your domain.  
The documentation can be found here: [allowlist-blocklist-ip](https://docs.netscaler.com/en-us/netscaler-k8s-ingress-controller/how-to/ip-whitelist-blacklist.html)  
Some examples:

### Allow only certain IPs

To allow only two specific IP addresses:

```code
apiVersion: citrix.com/v1
kind: rewritepolicy
metadata:
  name: allowlistip
spec:
  responder-policies:
    - servicenames:
        - frontend
      responder-policy:
        drop:
        respond-criteria: '!client.ip.src.TYPECAST_text_t.equals_any("allowlistip")'
        comment: 'Allowlist certain IP addresses'
  patset:
    - name: allowlistip
      values:
        - '10.1.170.55'
        - '10.2.16.9'
```

The servicenames corresponds to the service in OpenShift.

### Allow a CIDR

To allow a CIDR range only

```code
apiVersion: citrix.com/v1
kind: rewritepolicy
metadata:
  name: blocklistips1
spec:
  responder-policies:
    - servicenames:
        - frontend
      responder-policy:
        respondwith:
          http-payload-string: '"HTTP/1.1 403 Forbidden\r\n\r\n" + "Client: " + CLIENT.IP.SRC + " is not authorized to access URL:" + HTTP.REQ.URL.HTTP_URL_SAFE +"\n"'
        respond-criteria: '!client.ip.src.IN_SUBNET(10.1.170.0/24)'
        comment: 'Allowlist certain IPs'
```

### Blocklist IP addresses

Two blocklist two  IP addresses: 

```code
apiVersion: citrix.com/v1
kind: rewritepolicy
metadata:
  name: blocklistips
spec:
  responder-policies:
    - servicenames:
        - frontend
      responder-policy:
        respondwith:
        drop:
        respond-criteria: 'client.ip.src.TYPECAST_text_t.equals_any("blocklistips")'
        comment: 'Blocklist certain IPS'

  patset:
    - name: blocklistips
      values:
        - '10.1.170.5'
        - '10.8.16.43'
```

### Blocklist a CIDR

```code
apiVersion: citrix.com/v1
kind: rewritepolicy
metadata:
  name: blocklistips1
spec:
  responder-policies:
    - servicenames:
        - frontend
      responder-policy:
        respondwith:
          http-payload-string: '"HTTP/1.1 403 Forbidden\r\n\r\n" + "Client: " + CLIENT.IP.SRC + " is not authorized to access URL:" + HTTP.REQ.URL.HTTP_URL_SAFE +"\n"'
        respond-criteria: 'client.ip.src.IN_SUBNET(10.5.170.0/24)'
        comment: 'Blocklist certain IPs'
```

More examples can be found here: [allowlist-blocklist-ip](https://docs.netscaler.com/en-us/netscaler-k8s-ingress-controller/how-to/ip-whitelist-blacklist.html)
