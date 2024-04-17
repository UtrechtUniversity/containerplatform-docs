# GettingStarted
Here you will find information on how to connect to the platform through the steppingstone server.

## Login to OpenShift4 container platform [console](https://console.cp.its.uu.nl)

You cannot login directly to the steppingstone server steppingstone.its.uu.nl
But you can use it as a proxy to connect to the OpenShift4 container platform of the University Utrecht.

### Prerequisites
- You need to have an solisid at the University Utrecht with 2fa enabled.
- You need to have an account on the steppingstone server of the University Utrecht.
- You need to have an project/ namespace on the OpenShift4 container platform of the University Utrecht.

If you do no have these prerequisites, please contact one of the service delivery managers of the University Utrecht.
You can find all the information on how to do that on:

[manuals site UU](https://manuals.uu.nl/)

### Steps for the GUI
1. Add lines below to your `~/.ssh/config` file.

```bash
Host steppingstone
    HostName steppingstone.its.uu.nl
    IdentityFile ~/.ssh/<your-private-key>
    User <your-username>
    ForwardAgent yes
    Port 54322 (or 22)
```
Set environment variables for the proxy in your terminal. 
```bash
export HTTP_PROXY=socks5://127.0.0.1:6443
export HTTPS_PROXY=socks5://127.0.0.1:6443
```

2. Set up the proxy:
```bash
ssh -D localhost:6443 -N steppingstone
```

3. Set your browser to use the proxy:

Manual proxy configuration:
```bash
SOCKS Host: localhost Port: 6443
SOCKS v5
```


![sockproxy.png](./images/sockproxy.png)
4. Open the OpenShift4 console in your browser: [console](https://console.cp.its.uu.nl)

5. Start your epic work on OpenShift ;-)

### How to connect to OpenShift4 container platform walkthrough movie
<iframe src="https://player.vimeo.com/video/932020706?badge=0&amp;autopause=0&amp;player_id=0&amp;app_id=58479" width="480" height="270" frameBorder="1" class="giphy-embed" ; encrypted-media; gyroscope; picture-in-picture; allowfullscreen" title="oc_toegang2fa"></iframe>

### Steps for the CLI
Get your login command from the OpenShift4 console and execute it in your terminal.
Click on your username in the right top corner and select `Copy Login Command`.
```bash
oc login --token=<your-token> --server=https://localhost:6443
```

### Troubleshooting
If you have trouble connecting to the OpenShift4 api, you can try the following:
- Check if the proxy is set correctly.
- Check if the proxy is running.
- Check if the OpenShift4 console is reachable.
- Check if there are no conflicting settings in your `~/.ssh/config` file.
- 
If you have trouble reaching the api trough the cli, you can also setup your connection like so: 
#### Proxy setup for the CLI
Make sure to set the correct port e
```bash
ssh -i ~/.ssh/<your-private-key> 6443:console.cp.its.uu.nl:6443 -D 3333 <your-username>@steppingstone.its.uu.nl 
```
Use the oc login like so:
```bash
oc login --token=<your-token> --server=https://localhost:6443
``` 
