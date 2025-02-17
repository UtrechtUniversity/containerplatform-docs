# Basic commands

## **How to Monitor Pods**
#### Using the OpenShift Console:
Navigate to **Observe** > **Dashboards** or **Metrics**.
#### CLI Method:
View pods:
```bash
oc get pods -o wide -n <namespace>
```

## **How to Start a Debug Container**
#### **Using the OpenShift Console**
1. **Access the OpenShift Console:**
   Navigate to **Workloads > Pods**.

2. **Select the Pod:**
   Click on the pod you want to debug.

3. **Open Debug Terminal:**
   Use the **"Terminal"** tab in the GUI to execute commands directly in the container.  
   Alternatively, use the **Actions > Debug** option (if available), which starts a debug container or pod.  
   Go to the logs tab, and if your pods fails to start you will see a `debug` option.

#### **CLI Method**
1. **Start a debug session on a pod:**
    ```bash
    oc debug pod/<pod-name>
    ```
   This starts a debug pod based on the existing pod's configuration.

2. **Start a debug session with a specific image:**
    ```bash
    oc debug --image=<image-name> -t
    ```
   Example:
    ```bash
    oc debug --image=busybox -t
    ```
3. **Attach to a container:**
   After starting the debug pod, use `oc rsh` or `oc exec` to interact with the debug container.

## **How to connect to a pod using ssh**
#### **CLI Method**
Using `oc rsh`
1. **Start an interactive shell in a pod:**
    ```bash
    oc rsh <pod-name>
    ```
   Example:
      ```bash
      oc rsh my-app-pod
      ```
#### **Using `oc exec`**
1. **Run a command in a pod:**
    ```bash
    oc exec -it <pod-name> -- <command>
    ```
   Example:
    ```bash
    oc exec -it my-app-pod -- /bin/bash
    ```

2. **Start a bash shell:**
    ```bash
    oc exec -it <pod-name> -- bash
    ```
   If the container doesn't have bash, try `/bin/sh`:
    ```bash
    oc exec -it <pod-name> -- /bin/sh
    ```

#### **Troubleshooting Access**
1. If the pod has multiple containers, specify the container name:
    ```bash
    oc exec -it <pod-name> -c <container-name> -- /bin/bash
    ```
   Check the `oc get pods` output to confirm the pod name and container name.

## **How to debug network issues**
#### **CLI Method**
Use the netshoot image from quay.io:
```bash
oc run tmp-shell --rm -i --tty --image quay.io/tccr/netshoot
```
