# FAQ
## Frequently Asked Questions

### **1. What is OpenShift?**
OpenShift is a container orchestration platform built around Kubernetes, providing a consistent hybrid cloud foundation for building and scaling applications.

### **2. How is OpenShift different from previous versions?**
OpenShift introduced significant changes, including a rearchitected control plane based on operators, improved automation, and a streamlined installation process.

### **3. What are Operators in OpenShift?**
Operators are a method of packaging, deploying, and managing a Kubernetes application. They automate common operational tasks, such as installation, scaling, and backup, making application management more efficient.

### **4. How do I deploy applications on OpenShift?**
You can deploy applications on OpenShift using various methods, including using the web console, command-line interface (CLI), or GitOps workflows.

### **5. Can I use my preferred programming language with OpenShift?**
Yes, OpenShift supports applications developed in various programming languages, including Java, Python, Go, Node.js, and others.

### **6. What are some best practices for developing applications on OpenShift?**
Some best practices include using containerization, optimizing resource usage, implementing health checks, leveraging Kubernetes-native services, and monitoring application performance.

### **7. How can I integrate CI/CD pipelines with OpenShift?**
OpenShift integrates with popular CI/CD tools such as Jenkins, Tekton, and GitLab CI/CD. You can set up pipelines to automate the build, test, and deployment processes for your applications.

### **8. Is there a marketplace for pre-built application components on OpenShift?**
Yes, OpenShift OperatorHub provides a marketplace for finding and installing pre-built Kubernetes Operators to simplify application development and management tasks.

### **9. How does OpenShift handle security?**
OpenShift incorporates various security features, including role-based access control (RBAC), network policies, image scanning, encryption, and integration with security tools like Falco and Sysdig.

### **10. Where can I find resources for learning more about OpenShift development?**
You can explore the official OpenShift documentation, participate in community forums, attend workshops and webinars, and access online tutorials and courses offered by Red Hat and other providers.

### **11. What kind of storage do we supply?**
At the moment we do not supply object storage, but we do supply persistent storage for your applications.
You got three options:

- **Netapp storage** (preferred) RWX | ROX | RWO:  
   ReadWriteMany (RWX): `accessModes:    ReadWriteMany`  
   ReadOnlyMany (ROX): `accessModes:    ReadOnlyMany`  
   ReadWriteOnce (RWO): `accessModes:    ReadWriteOnce`
   > There is a guide on how to use NetApp storage on our documentation site named `NetApp storage`

- **Storage on openshift nodes** RWX:  
  ReadWriteMany (RWX): `accessModes:    ReadWriteMany`

**12. Why We Use Bitnami Unprivileged Containers?**

- **Security Compliance:**
   OpenShift uses Security Context Constraints (SCCs) to define permissions and access controls for pods. By default, it restricts the use of root user to minimize the risk of privilege escalation attacks. Bitnami unprivileged containers are designed to comply with these constraints, ensuring smooth deployment and operation.

- **Reduced Attack Surface:**
   Running containers as non-root reduces the attack surface, limiting the potential damage that can be done if a container is compromised. It prevents attackers from gaining elevated privileges on the host system.

- **Best Practices Alignment:**
   Following best practices in container security, such as running applications as non-root, is essential for modern cloud-native applications. Bitnami unprivileged containers are built with these best practices in mind.

- **Ease of Use:**
   Bitnami unprivileged containers come pre-configured to run as non-root users. This simplifies the process of deploying applications on OpenShift, as there is no need for additional configuration to drop privileges.

### **13. How to access the OpenShift console?**
   Please follow the guide at [Accessing the OpenShift console](content/basics/login.md)

### **14. How to request a TLS certificate for my application?**
   Please follow the guide at [Requesting a TLS certificate](content/guides/request-tls-cert.md)
