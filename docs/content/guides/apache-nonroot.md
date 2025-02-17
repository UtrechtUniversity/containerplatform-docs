# Run Apache as non root on OpenShift

## What are non-root containers?
By default, Docker containers are run as the root user. This means that you can do whatever you want in your container, such as install system packages, edit configuration files, bind privilege ports, adjust permissions, create system users and groups, access networking information. 
With a non-root container you can't do any of this . A non-root container should be configured for its main purpose, for example, run Apache. 

## Why use a non-root container?
It is the best practise for security. If there is a container engine security issue, running the container as an unprivileged user will prevent the malicious code from scaling permissions on the host node. Another reason is because some Kubernetes distributions, like OpenShift, forces you to use them. OpenShift runs containers with a random user, configured in your OpenShift project.

## Prequisites 
- an account on dockerhub
- a public repository named custom-httpd on dockerhub
- docker installed on your local machine
- a project in OpenShift

## How to create a non-root container?

In this example, an apache container from docker.io will be used.  
This container runs as root.  
It will be modified so that it runs on OpenShift.

## Run root apache container on OpenShift.
We are going to use a Dockerfile here and we will build the container and push it to dockerhub  
Replace DOCKER-USER with your own user account on dockerhub.

1. **Clone this repository**
    <a href="https://github.com/UtrechtUniversity/apache-non-root-example" target="_blank">UtrechtUniversity/apache-non-root-example</a><br>
    
    ```bash
    $ git clone https://github.com/UtrechtUniversity/apache-non-root-example
    $ cd apache-non-root-example
    ```

2. **Login Docker**
    ```bash
    login with your dockerhub account. It's best to create an access token and use it to push container images to dockerhub. See: [create access token docker](https://docs.docker.com/security/for-developers/access-tokens/)

    $ docker login registry-1.docker.io -u DOCKER-USER
    Password: [YOUR PERSONAL ACCESS TOKEN]
    Login Succeeded
    ```

3. **Build and run container unmodified**  
    First let's try to run a root container unmodified on OpenShift
    ```bash
    $ cat Dockerfile-v1
    FROM docker.io/httpd:2.4.59

    COPY ./html/ /usr/local/apache2/htdocs/
    ```

    ```bash
    $ docker build -t DOCKER-USER/custom-httpd:v1 -f Dockerfile-v1 .
    [+] Building 0.7s (7/7) FINISHED                                                                                                                                                                           docker:default
     => [internal] load build definition from Dockerfile-v1                                                                                                                                                              0.0s
     => => transferring dockerfile: 168B                                                                                                                                                                                 0.0s
     => [internal] load metadata for docker.io/library/httpd:2.4.59                                                                                                                                                      0.4s
     => [internal] load .dockerignore                                                                                                                                                                                    0.0s
     => => transferring context: 2B                                                                                                                                                                                      0.0s
     => [internal] load build context                                                                                                                                                                                    0.0s
     => => transferring context: 179B                                                                                                                                                                                    0.0s
     => [1/2] FROM docker.io/library/httpd:2.4.59@sha256:43c7661a3243c04b0955c81ac994ea13a1d8a1e53c15023a7b3cd5e8bb25de3c                                                                                                0.0s
     => CACHED [2/2] COPY ./html/ /usr/local/apache2/htdocs/                                                                                                                                                             0.0s
     => exporting to image                                                                                                                                                                                               0.0s
     => => exporting layers                                                                                                                                                                                              0.0s
     => => writing image sha256:4e54773780fcad018bd02919818e8e261f5072afdd83cf066b2ba6585ea332ac                                                                                                                         0.0s
     => => naming to docker.io/xxxxxx/custom-httpd:v1
    ```
    Then push it to dockerhub
    ```bash
    $ docker push DOCKER-USER/custom-httpd:v1
    The push refers to repository [docker.io/DOCKER-USER/custom-httpd]
    6bf7937baa7b: Pushed 
    3f5306cc4fdb: Pushed 
    2e035843b69b: Pushed 
    d138aa37a32d: Pushed 
    5f70bf18a086: Pushed 
    4cc26374e331: Pushed 
    5d4427064ecc: Pushed 
    v1: digest: sha256:14bc5ecd7354b20b810acfde1f2b2f6d24fd362511dba11d4940d6e045202114 size: 1779
    ```

    Now we try to deploy the root container on OpenShift.

    ```bash
    $ oc new-app --name=apache --image=DOCKER-USER/custom-httpd:v1
    --> Found container image 4e54773 (27 minutes old) from Docker Hub for "xxxxxxx/custom-httpd:v1"

        * An image stream tag will be created as "apache:v1" that will track this image

    --> Creating resources ...
        imagestream.image.openshift.io "apache" created
        deployment.apps "apache" created
        service "apache" created
    --> Success
        Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
         'oc expose service/apache' 
        Run 'oc status' to view your app.

    $ oc get pods
    NAME                      READY   STATUS             RESTARTS        AGE
    apache-6d456c64d6-kfdn6   0/1     CrashLoopBackOff   6 (3m21s ago)   8m57s

    $ oc logs pod/apache-6d456c64d6-kfdn6
    AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 10.228.8.243. Set the 'ServerName' directive globally to suppress this message
    (13)Permission denied: AH00072: make_sock: could not bind to address [::]:80
    (13)Permission denied: AH00072: make_sock: could not bind to address 0.0.0.0:80
    no listening sockets available, shutting down
    AH00015: Unable to open logs
    ```
    It complains that it can't bind to port 80, because it needs root privileges that is not allowed by OpenShift.
    To fix this, we first modify the port in the Container to for example 8080.

4. **Change container port to 8080**

    ```bash
    $ cat Dockerfile-v2
    FROM docker.io/httpd:2.4.59

    RUN sed -i 's/^Listen 80/Listen 8080/' /usr/local/apache2/conf/httpd.conf

    EXPOSE 8080

    COPY ./html/ /usr/local/apache2/htdocs/
    ```
    Here Listen is set to 8080 so it won't bind to an unprivileged port anymore. 
    ```bash
    $ docker build -t DOCKER-USER/custom-httpd:v2 -f Dockerfile-v2 .
    [+] Building 1.6s (9/9) FINISHED                                                                                                                                                                           docker:default
     => [internal] load build definition from Dockerfile-v2                                                                                                                                                              0.0s
     => => transferring dockerfile: 258B                                                                                                                                                                                 0.0s
     => [internal] load metadata for docker.io/library/httpd:2.4.59                                                                                                                                                      0.8s
     => [auth] library/httpd:pull token for registry-1.docker.io                                                                                                                                                         0.0s
     => [internal] load .dockerignore                                                                                                                                                                                    0.0s
     => => transferring context: 2B                                                                                                                                                                                      0.0s
     => CACHED [1/3] FROM docker.io/library/httpd:2.4.59@sha256:43c7661a3243c04b0955c81ac994ea13a1d8a1e53c15023a7b3cd5e8bb25de3c                                                                                         0.0s
     => [internal] load build context                                                                                                                                                                                    0.0s
     => => transferring context: 179B                                                                                                                                                                                    0.0s
     => [2/3] RUN sed -i 's/^Listen 80/Listen 8080/' /usr/local/apache2/conf/httpd.conf                                                                                                                                  0.3s
     => [3/3] COPY ./html/ /usr/local/apache2/htdocs/                                                                                                                                                                    0.1s
     => exporting to image                                                                                                                                                                                               0.2s
     => => exporting layers                                                                                                                                                                                              0.1s
     => => writing image sha256:9c4a9580c57a727449150674b22239a92311b2c9dc370016d1fe39f663848728                                                                                                                         0.0s
     => => naming to docker.io/DOCKER-USER/custom-httpd:v2
    ```
    Then push this image to dockerhub
    ```bash
    $ docker push DOCKER-USER/custom-httpd:v2
    The push refers to repository [docker.io/xxxxxx/custom-httpd]
    6bf7937baa7b: Layer already exists 
    0af891ef4775: Pushed 
    3f5306cc4fdb: Layer already exists 
    2e035843b69b: Layer already exists 
    d138aa37a32d: Layer already exists 
    5f70bf18a086: Layer already exists 
    4cc26374e331: Layer already exists 
    5d4427064ecc: Layer already exists 
    v2: digest: sha256:0eec468e3fab66e52cdcba77cbdf09d94241c326587f79aa1ea78bf71e4284ab size: 1987
    ```
    first delete the previous deployment
    ```bash
    $ oc delete all -l app=apache
    ```
    Then deploy the new container version.
    ```bash
    $ oc new-app --name=apache --image=DOCKER-USER/custom-httpd:v2
    --> Found container image 9c4a958 (4 minutes old) from Docker Hub for "xxxxxx/custom-httpd:v2"

        * An image stream tag will be created as "apache:v2" that will track this image

    --> Creating resources ...
        imagestream.image.openshift.io "apache" created
        deployment.apps "apache" created
        service "apache" created
    --> Success
        Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
         'oc expose service/apache' 
        Run 'oc status' to view your app.

    $ oc get pods
    NAME                     READY   STATUS   RESTARTS      AGE
    apache-5c44b7c4b-r7zrg   0/1     Error    2 (16s ago)   20s

    $ oc logs pod/apache-5c44b7c4b-r7zrg
    AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 10.228.8.244. Set the 'ServerName' directive globally to suppress this message
    AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 10.228.8.244. Set the 'ServerName' directive globally to suppress this message
    [Thu Jun 06 07:06:37.432550 2024] [core:error] [pid 1:tid 139802231318400] (13)Permission denied: AH00099: could not create /usr/local/apache2/logs/httpd.pid.9sL7NK
    [Thu Jun 06 07:06:37.432653 2024] [core:error] [pid 1:tid 139802231318400] AH00100: httpd: could not log pid to file /usr/local/apache2/logs/httpd.pid
    ```
    Still an error, it can't create files in /usr/local/apache2, because they are owned by root and our user is a non-root user.

5. **Change directory permissions**

    In OpenShift, the container user is always member of the root group (but is not root!).  
    The root group does not have any special permissions, unlike the root user.  
    You can use this to set the correct permissions for any random user OpenShift assigns to your container.
    ```bash
    $ cat Dockerfile-v3
    FROM docker.io/httpd:2.4.59

    RUN sed -i 's/^Listen 80/Listen 8080/' /usr/local/apache2/conf/httpd.conf

    EXPOSE 8080

    RUN chgrp -R 0 /usr/local/apache2 && \
        chmod -R g=u /usr/local/apache2

    COPY ./html/ /usr/local/apache2/htdocs/
    ```
    We make the root group owner of /usr/local/apache2 and give the root group the same permissions as the owner /usr/local/apache2 and underlying directories.

    ```bash
    $ docker build -t DOCKER-USER/custom-httpd:v3 -f Dockerfile-v3 .
    [+] Building 1.6s (10/10) FINISHED                                                                                                                                                                         docker:default
     => [internal] load build definition from Dockerfile-v3                                                                                                                                                              0.0s
     => => transferring dockerfile: 334B                                                                                                                                                                                 0.0s
     => [internal] load metadata for docker.io/library/httpd:2.4.59                                                                                                                                                      0.7s
     => [auth] library/httpd:pull token for registry-1.docker.io                                                                                                                                                         0.0s
     => [internal] load .dockerignore                                                                                                                                                                                    0.0s
     => => transferring context: 2B                                                                                                                                                                                      0.0s
     => [internal] load build context                                                                                                                                                                                    0.0s
     => => transferring context: 179B                                                                                                                                                                                    0.0s
     => [1/4] FROM docker.io/library/httpd:2.4.59@sha256:43c7661a3243c04b0955c81ac994ea13a1d8a1e53c15023a7b3cd5e8bb25de3c                                                                                                0.0s
     => CACHED [2/4] RUN sed -i 's/^Listen 80/Listen 8080/' /usr/local/apache2/conf/httpd.conf                                                                                                                           0.0s
     => [3/4] RUN chgrp -R 0 /usr/local/apache2 &&     chmod -R g=u /usr/local/apache2                                                                                                                                   0.3s
     => [4/4] COPY ./html/ /usr/local/apache2/htdocs/                                                                                                                                                                    0.1s
     => exporting to image                                                                                                                                                                                               0.3s
     => => exporting layers                                                                                                                                                                                              0.2s
     => => writing image sha256:904657b15291b7270bb553266135f9f0aad007577e3b708396099c63626fc7f0                                                                                                                         0.0s
     => => naming to docker.io/xxxxxx/custom-httpd:v3
    ```
    Then push it again to dockerhub
    ```bash
    $ docker push DOCKER-USER/custom-httpd:v3
    The push refers to repository [docker.io/xxxxxxx/custom-httpd]
    5846ea9b5d6a: Pushed 
    b1040c9ba42e: Pushed 
    0af891ef4775: Layer already exists 
    3f5306cc4fdb: Layer already exists 
    2e035843b69b: Layer already exists 
    d138aa37a32d: Layer already exists 
    5f70bf18a086: Layer already exists 
    4cc26374e331: Layer already exists 
    5d4427064ecc: Layer already exists 
    v3: digest: sha256:c1a06478b88fd72d9c36b16cdd03c724a50c83882ab67e6dc6e68013719265bb size: 2198
    ```
    Delete the old deployment again
    ```bash
    $ oc delete all -l app=apache
    service "apache" deleted
    deployment.apps "apache" deleted
    Warning: apps.openshift.io/v1 DeploymentConfig is deprecated in v4.14+, unavailable in v4.10000+
    imagestream.image.openshift.io "apache" deleted
    ```
    Create the new deployment

    ```bash
    $ oc new-app --name=apache --image=DOCKER-USER/custom-httpd:v3
    --> Found container image 904657b (3 minutes old) from Docker Hub for "xxxxxx/custom-httpd:v3"

        * An image stream tag will be created as "apache:v3" that will track this image

    --> Creating resources ...
        imagestream.image.openshift.io "apache" created
        deployment.apps "apache" created
        service "apache" created
    --> Success
        Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
         'oc expose service/apache' 
        Run 'oc status' to view your app.

    $ oc get pods
    NAME                      READY   STATUS    RESTARTS   AGE
    apache-84f948858f-hfjf2   1/1     Running   0          27s
    ```

6. **Check userid**  

    Now the container is running. You can check the user the container is running as.  
    This is of course another apache pod id than listed below
    ```bash
    $ oc exec pod/apache-84f948858f-hfjf2 id
    uid=1001100000(1001100000) gid=0(root) groups=0(root),1001100000
    ```

    It's running as user 1001100000. These settings are configured in the project.

    ```bash
    $ oc describe project/uu-xxxxxx | grep uid
                            openshift.io/sa.scc.uid-range=1001100000/10000
    ```

7. **test website**  

    Now let's check if we can actually access the html files. Because we used oc new-app the command also creates a service.  We only need to expose it. 

    ```bash
    $ oc expose svc/apache  --port=8080
    route.route.openshift.io/apache exposed
    ```
    ```bash
    $ oc get route
    NAME     HOST/PORT                                   PATH   SERVICES   PORT   TERMINATION   WILDCARD
    apache   apache-uu-xxxxxx.apps.cl01.cp.its.uu.nl          apache     8080                 None


    $ curl apache-uu-xxxxxx.apps.cl01.cp.its.uu.nl
    <!doctype html>
    <html>
      <head>
        <title>This is the title of the webpage!</title>
      </head>
      <body>
        <p>This is an example paragraph. Anything in the <strong>body</strong> tag will appear on the page, just like this <strong>p</strong> tag and its contents.</p>
      </body>
    </html>
    ```

<h2>Now the image runs as non root on OpenShift!!</h2>
