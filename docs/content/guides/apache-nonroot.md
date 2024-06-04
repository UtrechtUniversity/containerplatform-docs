# Run Apache as non root on OpenShift

## What are non-root containers?
By default, Docker containers are run as root users. This means that you can do whatever you want in your container, such as install system packages, edit configuration files, bind privilege ports, adjust permissions, create system users and groups, access networking information. 
With a non-root container you can't do any of this . A non-root container should be configured for its main purpose, for example, run Apache. 

## Why use a non-root container?
Mainly because it is a best practise for security. If there is a container engine security issue, running the container as an unprivileged user will prevent the malicious code from scaling permissions on the host node. Another reason is because some Kubernetes distributions, like OpenShift, forces you to use them. OpenShift runs containers with a random user.

## How to create a non-root container?

In this example, we are going to use the apache container from docker.io. 
This container runs as root.

### Run root apache container on OpenShift.
We are going to use a Dockerfile here and we will build the container and push it to quay.io. 
quay.io is a Red Hat container registry, but docker / harbor or other container registries can be used too 

```bash
$ cat Dockerfile
FROM docker.io/httpd:2.4.59

COPY ./html/ /usr/local/apache2/htdocs/
```
This Dockerfile just pulls the image from docker.io and copies an example index.html file into the htdocs directory. First we build te container.
```bash
$ podman build -t quay.io/cpjboon/custom-httpd:v1 .
STEP 1/2: FROM docker.io/httpd:2.4.59
STEP 2/2: COPY ./html/ /usr/local/apache2/htdocs/
COMMIT quay.io/cpjboon/custom-httpd:v1
--> 479f43e3f75
Successfully tagged quay.io/cpjboon/custom-httpd:v1
479f43e3f75314cf05f62514ec4e923844e48aebb877732e30eb6c6951e95d9a
```
Then push it do quay.io
```bash
$ podman push quay.io/cpjboon/custom-httpd:v1
Getting image source signatures
Copying blob 3f5306cc4fdb skipped: already exists
Copying blob 4cc26374e331 skipped: already exists
Copying blob 5d4427064ecc skipped: already exists
Copying blob 5f70bf18a086 skipped: already exists
Copying blob 2e035843b69b skipped: already exists
Copying blob d138aa37a32d skipped: already exists
Copying blob ef5fd7c5ac7d done
Copying config 479f43e3f7 done
Writing manifest to image destination
Storing signatures
```
Now we try to deploy the root container on OpenShift.
```bash
$ oc new-app --name=apache --image=quay.io/cpjboon/custom-httpd:v1
--> Found container image 479f43e (2 minutes old) from quay.io for "quay.io/cpjboon/custom-httpd:v1"

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
NAME                      READY   STATUS             RESTARTS      AGE
apache-85c68bf994-zw68c   0/1     CrashLoopBackOff   1 (13s ago)   17s
```
The container is not running and is giving errors.
```bash
$ oc logs pod/apache-85c68bf994-zw68c
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 10.229.9.70. Set the 'ServerName' directive globally to suppress this message
(13)Permission denied: AH00072: make_sock: could not bind to address [::]:80
(13)Permission denied: AH00072: make_sock: could not bind to address 0.0.0.0:80
no listening sockets available, shutting down
AH00015: Unable to open logs
```
It complains that it can't bind to port 80, because it needs root privileges that is not allowed by OpenShift.
To fix this, we first modify the port in the Container to for example 8080.

### Change container port to 8080
```bash
FROM docker.io/httpd:2.4.59

RUN sed -i 's/^Listen 80/Listen 8080/' /usr/local/apache2/conf/httpd.conf

EXPOSE 8080

COPY ./html/ /usr/local/apache2/htdocs/
```
Here Listen is set to 8080 so it won't bind to an unprivileged port anymore. 
```bash
$ podman build -t quay.io/cpjboon/custom-httpd:v2 .
STEP 1/4: FROM docker.io/httpd:2.4.59
STEP 2/4: RUN sed -i 's/^Listen 80/Listen 8080/' /usr/local/apache2/conf/httpd.conf
--> Using cache c8ec76d6b6ce807375e608befdc26f37edbd713761a8d1f6f477dcea17b8e0d0
--> c8ec76d6b6c
STEP 3/4: EXPOSE 8080
--> f2a7c75d984
STEP 4/4: COPY ./html/ /usr/local/apache2/htdocs/
COMMIT quay.io/cpjboon/custom-httpd:v2
--> e4f758c012e
Successfully tagged quay.io/cpjboon/custom-httpd:v2
e4f758c012e9bd009f7be39769e905cf5aeefb2c990e868ae12ee541aa3fb3a0
```
first let's delete the previous deployment
```bash
$ oc delete all -l app=apache
```
Then deploy the new container version.
```bash
$ oc new-app --name=apache --image=quay.io/cpjboon/custom-httpd:v2
--> Found container image 21827a5 (6 minutes old) from quay.io for "quay.io/cpjboon/custom-httpd:v2"

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
NAME                      READY   STATUS   RESTARTS      AGE
apache-5b4b7f7977-22pkl   0/1     Error    2 (23s ago)   36s

$ oc logs pod/apache-6cd4dd6894-4f4ph
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 10.229.9.71. Set the 'ServerName' directive globally to suppress this message
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 10.229.9.71. Set the 'ServerName' directive globally to suppress this message
[Tue May 28 08:53:07.932869 2024] [core:error] [pid 1:tid 140564341221248] (13)Permission denied: AH00099: could not create /usr/local/apache2/logs/httpd.pid.AMz5TA
[Tue May 28 08:53:07.932977 2024] [core:error] [pid 1:tid 140564341221248] AH00100: httpd: could not log pid to file /usr/local/apache2/logs/httpd.pid
```
Still an error, it can't create files in /usr/local/apache2, because they are owned by root and our user is a non-root user.

### Change directory permissions 
In OpenShift, the container user is always member of the root group (but is not root!). 
The root group does not have any special permissions, unlike the root user.
You can use this to set the correct permissions for any random user OpenShift assigns to your container.
```bash
FROM docker.io/httpd:2.4.59

RUN sed -i 's/^Listen 80/Listen 8080/' /usr/local/apache2/conf/httpd.conf

EXPOSE 8080

RUN chgrp -R 0 /usr/local/apache2 && \
    chmod -R g=u /usr/local/apache2

COPY ./html/ /usr/local/apache2/htdocs/
```
We make the root group owner of /usr/local/apache2 and give the root group the same permissions as the owner /usr/local/apache2 and underlying directories.
```bash
$ podman build -t quay.io/cpjboon/custom-httpd:v3 .
STEP 1/5: FROM docker.io/httpd:2.4.59
STEP 2/5: RUN sed -i 's/^Listen 80/Listen 8080/' /usr/local/apache2/conf/httpd.conf
--> Using cache c8ec76d6b6ce807375e608befdc26f37edbd713761a8d1f6f477dcea17b8e0d0
--> c8ec76d6b6c
STEP 3/5: EXPOSE 8080
--> Using cache f2a7c75d98432b0ffd540aa9641616d45cca87256608e2f9b231253278af053b
--> f2a7c75d984
STEP 4/5: RUN chgrp -R 0 /usr/local/apache2 &&     chmod -R g=u /usr/local/apache2
--> Using cache 9dba448750a309a65e777ab92e504fba800cc369a6d8d7bf5288b72b8b3fabea
--> 9dba448750a
STEP 5/5: COPY ./html/ /usr/local/apache2/htdocs/
--> Using cache c6def2336e480d6f413dba3136516a13f20d75995c552ce7ad900e64bccf4f1b
COMMIT quay.io/cpjboon/custom-httpd:v3
--> c6def2336e4
Successfully tagged quay.io/cpjboon/custom-httpd:v3
c6def2336e480d6f413dba3136516a13f20d75995c552ce7ad900e64bccf4f1b

$ oc delete all -l app=apache
service "apache" deleted
deployment.apps "apache" deleted
Warning: apps.openshift.io/v1 DeploymentConfig is deprecated in v4.14+, unavailable in v4.10000+
imagestream.image.openshift.io "apache" deleted

$ oc new-app --name=apache --image=quay.io/cpjboon/custom-httpd:v3
--> Found container image c6def23 (2 minutes old) from quay.io for "quay.io/cpjboon/custom-httpd:v3"

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
apache-58d8bdf4d6-kvcx4   1/1     Running   0          7s
```
Now the container is running. You can check the user
```bash
$ oc exec pod/apache-58d8bdf4d6-kvcx4 -- id
uid=1001100000(1001100000) gid=0(root) groups=0(root),1001100000
```
It's running as user 1001100000. These settings are configured in the project.
```bash
$ oc describe project/uu-boon0031 | grep uid
                        openshift.io/sa.scc.uid-range=1001100000/10000
```

### expose service and access website
Now let's check if we can actually access the html files.  
Because we used oc new-app the command also creates a service. 
We only need to expose it. 

```bash
$ oc expose svc/apache  --port=8080
route.route.openshift.io/apache exposed

$ oc get route
NAME     HOST/PORT                                   PATH   SERVICES   PORT   TERMINATION   WILDCARD
apache   apache-uu-boon0031.apps.cl01.cp.its.uu.nl          apache     8080                 None
$ curl apache-uu-boon0031.apps.cl01.cp.its.uu.nl

<html>
        <head>
                Example Apache Website
        </head>
        <body>
                <h1> Hello World! </h1>
        </body>
</html>
```

## Use 
