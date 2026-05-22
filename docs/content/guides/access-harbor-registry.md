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
