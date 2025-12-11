## X-Forward-For

The X-Forwarded-For (XFF) HTTP header is a standard method used by web servers to identify the original client's IP address when a request passes through a proxy or load balancer. 
It essentially tells the server which IP address the request originated from, allowing the server to know the user's real IP even if the request was first routed through another server. 
Some web servers might want to use this to store the original IP in the logging or maybe store some webserver access statistics.  The loadbalancer is running on layer 7, so it does not uses the proxy protocol.  

To enable x-forward-for for the service http: 

```code
apiVersion: citrix.com/v1
kind: rewritepolicy
metadata:
  name: httpxforwardedforadd
spec:
  ingressClassName: nsic-vpx
  rewrite-policies:
    - servicenames:
        - http
      rewrite-policy:
        operation: insert_http_header
        target: X-Forwarded-For
        modify-expression: client.ip.src
        comment: 'HTTP Initial X-Forwarded-For header add'
        direction: REQUEST
        rewrite-criteria: 'HTTP.REQ.HEADER("X-Forwarded-For").EXISTS.NOT'

    - servicenames:
        - http
      rewrite-policy:
        operation: replace
        target: HTTP.REQ.HEADER("X-Forwarded-For")
        modify-expression: 'HTTP.REQ.HEADER("X-Forwarded-For").APPEND(",").APPEND(CLIENT.IP.SRC)'
        comment: 'HTTP Append X-Forwarded-For IPs'
        direction: REQUEST
        rewrite-criteria: 'HTTP.REQ.HEADER("X-Forwarded-For").EXISTS'
```

This should link to the Kubernetes service you use. In this case, the service name is http.
