# FAQ
Here you will find answers to frequently asked questions about the Container Platform of the University Utrecht.

## Frequently Asked Questions

**1. What is OpenShift 4?**
OpenShift 4 is a container orchestration platform built around Kubernetes, providing a consistent hybrid cloud foundation for building and scaling applications.

**2. How is OpenShift 4 different from previous versions?**
OpenShift 4 introduced significant changes, including a rearchitected control plane based on operators, improved automation, and a streamlined installation process.

**3. What are Operators in OpenShift 4?**
Operators are a method of packaging, deploying, and managing a Kubernetes application. They automate common operational tasks, such as installation, scaling, and backup, making application management more efficient.

**4. How do I deploy applications on OpenShift 4?**
You can deploy applications on OpenShift 4 using various methods, including using the web console, command-line interface (CLI), or GitOps workflows.

**5. Can I use my preferred programming language with OpenShift 4?**
Yes, OpenShift 4 supports applications developed in various programming languages, including Java, Python, Go, Node.js, and others.

**6. What are some best practices for developing applications on OpenShift 4?**
Some best practices include using containerization, optimizing resource usage, implementing health checks, leveraging Kubernetes-native services, and monitoring application performance.

**7. How can I integrate CI/CD pipelines with OpenShift 4?**
OpenShift 4 integrates with popular CI/CD tools such as Jenkins, Tekton, and GitLab CI/CD. You can set up pipelines to automate the build, test, and deployment processes for your applications.

**8. Is there a marketplace for pre-built application components on OpenShift 4?**
Yes, OpenShift OperatorHub provides a marketplace for finding and installing pre-built Kubernetes Operators to simplify application development and management tasks.

**9. How does OpenShift 4 handle security?**
OpenShift 4 incorporates various security features, including role-based access control (RBAC), network policies, image scanning, encryption, and integration with security tools like Falco and Sysdig.

**10. Where can I find resources for learning more about OpenShift 4 development?**
You can explore the official OpenShift documentation, participate in community forums, attend workshops and webinars, and access online tutorials and courses offered by Red Hat and other providers.

**11. What kind of storage do we supply?**
At the moment we do not supply object storage, but we do supply persistent storage for your applications.
You got two options:

1. (preferred) Netapp Trident storage on openshift nodes. You can use:

- ReadWriteMany (RWX): `accessModes:    ReadWriteMany`
- ReadOnlyMany (ROX): `accessModes:    ReadOnlyMany`
- ReadWriteOnce (RWO): `accessModes:    ReadWriteOnce`

There is a guide on how to use Trident on our documentation site.

2. Storage on openshift nodes. Make sure you use RWO for your PVC's. `accessModes:    ReadWriteOnce`

**12. Why We Use Bitnami Unprivileged Containers?**

- **Security Compliance:**
   OpenShift uses Security Context Constraints (SCCs) to define permissions and access controls for pods. By default, it restricts the use of root user to minimize the risk of privilege escalation attacks. Bitnami unprivileged containers are designed to comply with these constraints, ensuring smooth deployment and operation.

- **Reduced Attack Surface:**
   Running containers as non-root reduces the attack surface, limiting the potential damage that can be done if a container is compromised. It prevents attackers from gaining elevated privileges on the host system.

- **Best Practices Alignment:**
   Following best practices in container security, such as running applications as non-root, is essential for modern cloud-native applications. Bitnami unprivileged containers are built with these best practices in mind.

- **Ease of Use:**
   Bitnami unprivileged containers come pre-configured to run as non-root users. This simplifies the process of deploying applications on OpenShift, as there is no need for additional configuration to drop privileges.
