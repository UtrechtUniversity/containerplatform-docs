# Seal your secrets

## What is Sealed Secrets?
Sealed Secrets is a tool that allows you to encrypt Kubernetes secrets into a SealedSecret resource, which can be safely stored in version control systems like Git. The SealedSecret can only be decrypted by the Sealed Secrets controller running in the OpenShift cluster, ensuring that sensitive information remains secure.
The controller is managed by the ITS Linux team.

## Why use Sealed Secrets?
Sealed Secrets provide a way to manage sensitive information in a secure manner while still allowing you to version control your secrets. This is particularly useful in environments where you need to share configurations or collaborate with others without exposing sensitive data.

## How to seal your secrets
To seal your secrets, follow these steps:  
1. **Install kubeseal**: Ensure you have the `kubeseal` CLI tool installed on your local machine. You can download it from the [Sealed Secrets GitHub releases page](https://github.com/bitnami-labs/sealed-secrets/tree/main?tab=readme-ov-file#kubeseal).  
2. **Create a Kubernetes Secret**: First, create a standard Kubernetes Secret manifest file (e.g., `mysecret.yaml`):
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: mysecret
     namespace: mynamespace
   type: Opaque
   data:
     username: dXNlcm5hbWU=  # base64 encoded value
     password: cGFzc3dvcmQ=  # base64 encoded value
   ```
3. **Seal the Secret**: Use the `kubeseal` command to seal the secret. Make sure to specify the correct namespace and output format:
   ```bash
   kubeseal --cert=https://seal.cp.its.uu.nl/v1/cert.pem --format=yaml < my-secret.yaml > my-secret-sealed.yaml
   ```
   The secrets now looks something like this:
    ```yaml
    apiVersion: bitnami.com/v1alpha1
    kind: SealedSecret
    metadata:
      creationTimestamp: null
      name: mysecret
      namespace: mynamespace
    spec:
      encryptedData:
        password: AgBoOoLdoqqhmbt6nsyPlaw3sE4tAforFhkz5qXxnvNisv8LOfuO10BDnoZ6CmIr8Oorn4p9eCr6UPj/n2oFVB+Eu8Itjl2uQonnOhuuwFXHOiAodicbWiIwYxJCo3oX8+xJJt6YOfMc2VsUoi1C3sy0unV+ZOEgZUCQY/UGeiKeaxTuSiKMoQ+4vjsJuUoxaM/7bqP16wsv1sgySkoHNegX1SbNz9clg1CPFthD13ehlVKdt2g9dILzytW4geuWwQZS34ZO1VnrQzMFcGXApnyHB8PI3dmcVj284bw3ayROP8OPp25LYhey5GnGu/UkUGqKDK7ue13aARv+ZHwpiNVlN9zRkooaAez0kaOC2UZ2Eg91x//m83rdyc7+wGb3prHwVm3YulaujWZ0lBKfuVhlLR8Z6dpE+AgP1FGGPP78hRFFkmY0EJgWHRgj9EQME6r8ygFDYwLT96DuNUX3HPPiZVB6mHcJ7qRhfD6amx1ZMX/weUkhKKm1zh6GQTk46gF3PtEvfz8CN7EoQDOKU5McNZt/kZTYMjLDBLCnxcCsbTDf2n4JXQIshQ3hqPwZdurZqIAURYYEUJ1ikNXNGtgaTPseUXjIvy4eu61W8qp+UJghm+6GjmOw+fdatp/41hy4zFY+y8PCWatuQ/ki1PTOJuEkFAlY5zH+iYYZ7U6r/qCyMYcK18upQWR6b/GIV+uMz1/mwtSqfA==
        username: AgB5Iu4KNKFxCjwDLQVT5BiwVUkXhCocB6IgBzBqnJkszwJQv2uFlac74xRRw7kxS+sObfy5u3Sai6nNR389ojuslk7QSi3kbG8OKan4Bt3qZHZXlP9uk9ogvEgjjL132j8rhAPy/ZULO26jjFDSddd9GWpygmHZjZHIdpX28KbI7lYJ0PpYj+WGKhA/6FHTXk42sTJPnq55tXUUosuexYc3VYoU84BbfkilhPYSsRog3seYWSZLjIqKf3XXgP/auSI1OeGfdMvKVs127J3cVHEc7fE22jnIvkldOF9bpo5MLupQ5/ymGO6t7QRshk5jj/NsU0ELQMERBwVIpQbeQhfGhHv/+W4p4yoQ53BxP/DImGZ6KgXBfb3mKZ2W/B7WUpw1i9lFe3VLuhZ2lF4uj+3qobqmFEEbnlbZTPYT9qN9OoNMQFllh8fcmzKBjhKecpVgXTieaFsqKAS+KZIH5cczg7PG2VzHA7IQ2FIHQBYPCWiOnL/bFl5Vbxm9U2EcENjO/DyjppzRhpE620yWftnnJ2m69gCOdoW7kmvgwwvOU1W/a6UKJ6tDut2hXz08PvtPA2izEYjloQzZeGkbXIPNagAG5cScwWB4NYPFGtZlACtZ72UYNGk8D0PzE3HNa7Ws9AiuK+A85CMkv1rIwaXsCdkqes7T80cXB3TXcRZZ8pvnemVPYAKsfnhf6qq6KT/7B9Zln+AVSA==
      template:
        metadata:
          creationTimestamp: null
          name: mysecret
          namespace: mynamespace
        type: Opaque
    ```
4. **Apply the SealedSecret**: Finally, apply the sealed secret to your OpenShift cluster:
   ```bash
   kubectl apply -f mysealedsecret.yaml
   ```