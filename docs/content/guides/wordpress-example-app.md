# wordpress-example-app
How to deploy an wordpress app on openshift running in unpriviliged containers

### Prerequisites

**Have a dns entry for your site**  
  Create a netwerk dns change in topdesk to apply for your dns name.  
  e.g. `wp-example.its.uu.nl`

## Steps

1. **Clone this repo**  
[UtrechtUniversity/wordpress-example-app](https://github.com/UtrechtUniversity/wordpress-example-app)   
`git clone https://github.com/UtrechtUniversity/wordpress-example-app`  

2. **Replace the `<your-...>` with your own data in the yaml files below**  

     * [x] mariadb-secret.yaml
     * [x] wordpress-cm.yaml
     * [x] wordpress-ingress.yaml
     * [x] wordpress-secret.yaml  
   e.g.  
   `wordpress-email: <your-email>` with `wordpress-email: thisismyemail@email.com`

3. **Run the script wordpress-app.sh or oc command**  
   `bash wordpress-app.sh` or `oc apply -f .`  
   > FYI. `oc apply -f .` could lead to a race condition, that is why I made the above script. So the correct order of resource creation is applied.  

4. **Login to your admin site**  
   Go to the url you set in the ingress file, and append /admin to the url.  
   e.g [wp-example.its.uu.nl/admin](https://wp-example.its.uu.nl/admin)  
   > Login with the credential you have set.
