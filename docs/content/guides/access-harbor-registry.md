# How to use harbor container registry

## Prerequisites
- [x] You need to have a SolisID
- [x] You need to have Docker / Podman / Buildah installed locally to be able to tag and push images

#### Setup the user
1. Login to the harbor UI using the `LOGIN WITH SOLISID` option: https://harbor.its.uu.nl

#### Create a project
1. By default you should have the proper permissions to create a new project.
> The project name will be part of the URL, so choose carefully.
2. Create a new project and set the access level to Public by checking the box.
> By checking the box, anyone can pull your image without authenticating.

#### Authenticating on the commandline
1. In the UI, click your username on the top right, than click `User Profile`
2. At the bottom of the pop-up you see `CLI secret`. Copy this value. 
3. Run: `docker login harbor.its.uu.nl`
> Make sure Docker is started on your machine
4. For a username, type the username as mentioned in the pop-up (your SolisID)
5. As for the password, paste the `CLI secret` from the pop-up.
6. Now you should see this message: `Login Succeeded`

#### Pushing your Docker image
1. Run: `docker push <name of your image>`
> Make sure your docker images is tagged with harbor.its.uu.nl/<project name>/<name of your image>
2. The output should be something like:
```
The push refers to repository [harbor.its.uu.nl/<project name>/<name of your image>]
98bb9115bf90: Pushed
2b8323ca012e: Pushed
16c9c4a8e9ee: Pushed
f7f100301c28: Pushed
68a26c36cf0c: Pushed
a93560b4393a: Pushed
0d0f8c631f0a: Pushed
adc54e92deb2: Pushed
f5c3e456f51e: Pushed
1.29: digest: sha256:c25290b2e274dbbbc1d13f74a56921082f1154b7a8b85e666d374f58d958b4cc size: 856
```

#### use robot accounts
in harbor, you can create robot accounts to run automated operations. This is especially useful when you have a private project / repository in Harbor.

1. create Robot account  
    Login to harbor, select Robot accounts and +NEW ROBOT ACCOUNT  
    give it a meaningful name, here: 
  
    Name: harbor-openshift-cd  
    Description: deploy on openshift from harbor  
    expiration time: 30 days  
    NEXT  
    NEXT (Don't select any system permissions)  
    Select Project Permissions  
     first select the repositories and then you can set the permission on the repository. 
     select repository: pull    
     FINISH  
  
    Now you get to see the Secret token. This should be stored in a vault or in a GitHub secret etc.

2. create pull secret in openshift

    To use the robot account in OpenShift, you first have to create a docker-registry secret.  
    You should create a sealed secret for this. For details about sealed secrets see: [sealed-secrets](https://docs.cp-acc.its.uu.nl/content/guides/seal-your-secrets/#how-to-seal-your-secrets)  
    You can store this sealed secret in Git or use a command like below:  
    
    Fill in the correct --docker-username and --docker-password from step 1.

    ```bash
    oc create secret docker-registry harbor-pull-secret \
    --docker-server=harbor.its.uu.nl \
    --docker-username='CHOSEN NAME FROM STEP 1' \
    --docker-password='GENERATED TOKEN FROM STEP 1' \
    --docker-email='example@uu.nl' -o yaml --dry-run=client | \
    kubeseal --cert=https://seal.cp.its.uu.nl/v1/cert.pem --format=yaml | \
    oc apply -f -
    ```

3. Create deployment without image pull secret

    Now first let's create a deployment without the pull secret to show that the Kubelet can't pull an image from the private repository.

    ```
    cat <<EOF | oc apply -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      creationTimestamp: null
      labels:
        app: webserver
       name: webserver
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: webserver
      template:
        metadata:
          labels:
            app: webserver
        spec:
          containers:
          - image: harbor.its.uu.nl/harbor-robot-test/nginx:stable-alpine
            name: nginx
            imagePullPolicy: Always
            ports:
            - containerPort: 8080
    EOF
    ```

    ```bash
    $ oc get pods
    NAME                         READY   STATUS             RESTARTS   AGE
    webserver-7578dcbdbd-28b6n   0/1     ImagePullBackOff   0          2s
  
    $ oc describe pod webserver-7578dcbdbd-28b6n
    .....
      Warning  Failed          90m (x3 over 90m)  kubelet            Failed to pull image "harbor.its.uu.nl/harbor-robot-test/nginx:stable-alpine": unable to pull image or OCI artifact: pull image err: initializing source docker://harbor.its.uu.nl/harbor-robot-test/nginx:stable-alpine: reading manifest stable-alpine in harbor.its.uu.nl/harbor-robot-test/nginx: unauthorized: unauthorized to access repository: harbor-robot-test/nginx, action: pull: unauthorized to access repository: harbor-robot-test/nginx, action: pull; artifact err: get manifest: build image source: reading manifest stable-alpine in harbor.its.uu.nl/harbor-robot-test/nginx: unauthorized: unauthorized to access repository: harbor-robot-test/nginx, action: pull: unauthorized to access repository: harbor-robot-test/nginx, action: pull
    ```

    As you can see, the docker repository on Harbor is private so the Kubelet can't pull the image.

4. Create deployment with image pull secret

    ```
    cat <<EOF | oc apply -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        app: webserver
      name: webserver
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: webserver
      template:
        metadata:
          labels:
            app: webserver
        spec:
          imagePullSecrets:
          - name: harbor-pull-secret
          containers:
          - image: harbor.its.uu.nl/harbor-robot-test/nginx:stable-alpine
            name: nginx
            imagePullPolicy: Always
            ports:
            - containerPort: 8080
    EOF
    ```
  
    ```
    $ oc get pods
    NAME                         READY   STATUS    RESTARTS   AGE
    webserver-85d66678f9-ljxnz   1/1     Running   0          4s
    
    $ oc describe pod webserver-85d66678f9-ljxnz | grep image
      Normal  Pulling         90m   kubelet            Pulling image "harbor.its.uu.nl/harbor-robot-test/nginx:stable-alpine"
      Normal  Pulled          90m   kubelet            Successfully pulled image "harbor.its.uu.nl/harbor-robot-test/nginx:stable-alpine" in 696ms (696ms including waiting). Image size: 55201635 bytes.
    ```
  
    So now a robot account with minimal privileges (pull) on a private project is used to pull an image.  
    This is much more secure than using user accounts for pulling images.