# wordpress-example-app
How to deploy a WordPress app on OpenShift running in unpriviliged containers

### Prerequisites

- [x] **Have a DNS entry for your site**  
  Create a network DNS change in Topdesk to apply for your DNS name.  
  e.g. `wp-example.its.uu.nl`

## Steps

1. **Clone this repo**  
<a href="https://github.com/UtrechtUniversity/wordpress-example-app" target="_blank">UtrechtUniversity/wordpress-example-app</a>
`git clone https://github.com/UtrechtUniversity/wordpress-example-app`  

2. **Replace the `<your-...>` with your own data in the yaml files below**  

     * `mariadb-secret.yaml`
     * `wordpress-cm.yaml`
     * `wordpress-ingress.yaml`
     * `wordpress-secret.yaml`  
  
     e.g. `wordpress-email: <your-email>` with `wordpress-email: thisismyemail@email.com`

3. **Run the script wordpress-app.sh or oc command**  
   `bash wordpress-app.sh` or `oc apply -f .`  
   > FYI. `oc apply -f .` could lead to a race condition, that is why I made the above script. So the correct order of resource creation is applied.  

4. **Login to your admin site**  
   Go to the url you set in the ingress file, and append /admin to the url.  
   e.g <a href="https://wp-example.its.uu.nl/admin" target="_blank">wp-example.its.uu.nl/admin</a>
   > Login with the credential you have set.
