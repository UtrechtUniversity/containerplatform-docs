# These are the steps you can follow to access the internal OpenShift container registry.

### Prerequisites
- [x] You need to have an account and project on the Container Platform.
- [x] You need to have Docker / Podman / Buildah installed locally to be able to tag and push images
- [x] You need to have the OpenShift client tools installed.
- [x] You need to have at least edit rights on your project / projects, which all developers should have.
> In this example, we use a local build custom httpd container to push to OpenShift (localhost/custom-httpd:v4)

### Steps

1. Login to the OpenShift GUI.

    go to <a href="https://console.cp.its.uu.nl" target="_blank">OpenShift Console</a><br>
    Enter your UU credentials and MFA token. <br>
    For more information about logging in visit: <a href="https://docs.cp.its.uu.nl/content/basics/login/" target="_blank">openshift Login</a><br> <br>
    Click your username and the top right, followed by copy login command. <br>
    Press display token, copy login with this token. Such as:
    ```bash
    oc login --token=sha256~yeahright --server=https://api.cl01.cp.its.uu.nl:6443
    ```
2. Login to the registry.

    You can use your username and token to log in to the internal registry:
    ```bash
    $ docker login -u `oc whoami` -p `oc whoami --show-token` registry.cp.its.uu.nl
    Login Succeeded
    ```

3. We now will tag the locally build http container.

    The tag should have 4 fields: <br><br>
  
    REGISTRY / PROJECT / IMAGE_NAME / TAG 
    in this case: <br>
  
    REGISTRY: registry.cp.its.uu.nl <br>
    PROJECT: OPENSHIFT_PROJECT <br>
    IMAGE_NAME: custom-httpd <br>
    TAG: v3 <br>
  
    ```bash
    $ docker tag localhost/custom-httpd:v4 registry.cp.its.uu.nl/OPENSHIFT_PROJECT/custom-httpd:v3
    ```
    here replace OPENSHIFT_PROJECT with the project you have access too, such as your own project (uu-xxxx) or a project for your team. <br>
 
4. Push the image.

    ```bash
    $ docker push registry.cp.its.uu.nl/OPENSHIFT_PROJECT/custom-httpd:v4
    The push refers to repository [registry.cp.its.uu.nl/OPENSHIFT_PROJECT/custom-httpd]
    ffef929ba8dc: Pushed 
    3dc4a1e9704d: Pushed 
    b995345c8e67: Pushed 
    .....
    v4: digest: sha256:577fbe83f56331c1859a015127694a3e66cddc37abc0f01edafd153f226cdccc size: 2198
    ```

5. Show image
    ```bash
    $ oc describe is/custom-httpd 
    Name:			custom-httpd
    Namespace:		OPENSHIFT_PROJECT
    Created:		7 days ago
    Labels:			<none>
    Annotations:		<none>
    Image Repository:	registry.cp.its.uu.nl/OPENSHIFT_PROJECT/custom-httpd
    Image Lookup:		local=false
    Unique Images:		1
    Tags:			1
  
    v4
      no spec tag
    
      * image-registry.openshift-image-registry.svc:5000/OPENSHIFT_PROJECT/custom-httpd@sha256:577fbe83f56331c1859a015127694a3e66cddc37abc0f01edafd153f226cdccc
          5 minutes ago
    ```
  
6. Create deployment with Container Image.

    Deploying applications to OpenShift can be done on several ways, here as example the oc new-app command is used to create a deployment.
    ```bash
    $ oc new-app --image=registry.cp.its.uu.nl/OPENSHIFT_PROJECT/custom-httpd:v4
    --> Found container image 4b6c1e6 (6 weeks old) from registry.cp.its.uu.nl for "registry.cp.its.uu.nl/OPENSHIFT_PROJECT/custom-httpd:v4"
  
        * An image stream tag will be created as "custom-httpd:v4" that will track this image
  
    --> Creating resources ...
        deployment.apps "custom-httpd" created
        service "custom-httpd" created
    --> Success
        Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
         'oc expose service/custom-httpd' 
        Run 'oc status' to view your app.
    ```
7. Remarks
    
    Note that by default, you can't access container images from other users, even if you have access to several projects. <br>
    Sometimes it can be desirable to have a project that holds all the container images and other acc / prd project that use those containers. <br>
    In such a setup, service accounts should be used which have the system:image-puller role attached. <br>
    If that is required, the Linux team can be contacted to create the service account / rolebinding.
