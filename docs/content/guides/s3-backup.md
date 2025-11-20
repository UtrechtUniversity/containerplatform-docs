# Example backing up files to S3

This is an example how to backup files to an S3 bucket.  
An S3 bucket is not a classical block filesystem so it should not be used like that. An S3 bucket should hold static files like pictures / movies / text files etc.

## 1. Prerequisites

- [x] **S3 bucket (contact our storageteam)**
- [x] **S3 credentials (access key id and secret access key)**

To communicate with the bucket, you need to have credentials (Access Key and Secret Access Key).  
Contact the storage team to request an S3 bucket and the required credentials.  
within the UU, netapp storage is used that also supports S3 object storage.  
You need a CLI tool that knows how to talk to S3. Normally you would add this CLI to your container image or use a sidecar container or use libraries to add S3 support to your application.
In this example, the amazon/aws-cli container image is used.
 
## 2. Create secret

The AWS CLI needs some configuration to connect to the correct endpoint / buckets.  
This configuration can be set using environment variables. The following variables should be set:

* AWS_ACCESS_KEY_ID
* AWS_SECRET_ACCESS_KEY
* AWS_ENDPOINT_URL

These variables can be created using a secret:

```bash
oc create secret generic aws-credentials \
  --from-literal=access_key_id=XXXXXXXX \
  --from-literal=secret_access_key_id=XXXXXXXX \
  --from-literal=endpoint="https://s3.uu.nl"
```

Then you can use an env section in your deployment.

## 3. Create deployment

```
cat > deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aws-test
spec:
  replicas: 1
  selector:
    matchLabels:
      deployment: aws
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        deployment: aws
    spec:
      containers:
      - image: amazon/aws-cli
        imagePullPolicy: IfNotPresent
        env:
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: access_key_id
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: secret_access_key_id
        - name: AWS_ENDPOINT_URL
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: endpoint
        name: aws
        command: ["/bin/bash", "-c", "sleep 3600"]
EOF
```

```bash
oc create -f deployment.yaml
```

## 4. Backup and Restore tests
### 4.1 Test connection

First let's test the connection by running a shell in the aws cli pod.

```
$ oc get pods
NAME                        READY   STATUS    RESTARTS   AGE
aws-test-55fb479cbd-6vn92   1/1     Running   0          58m
```

```
$ oc rsh aws-test-55fb479cbd-6vn92
sh-5.2$ 
```

Then you aws s3 ls to check if the connection works.

```bash
sh-5.2$ aws s3 ls
2025-01-06 12:36:27 test-bucket
```

The bucket is visible so the connection works.

### 4.2 Copy files recursively

Now copy a lot of files to S3.  
Let's first create some random files in /tmp so we have something to copy

```
for i in {0001..1000}; do   echo "This is file number $i" > "/tmp/file_${i}.txt"; done
```

In this example, we copy the whole tmp directory from to pod to S3.

```bash
aws s3 cp /tmp s3://test-bucket/tmp --recursive
....
upload: ../tmp/file_1000.txt to s3://test-bucket/tmp/file_1000.txt
upload: ../tmp/file_0994.txt to s3://test-bucket/tmp/file_0994.txt
upload: ../tmp/file_0998.txt to s3://test-bucket/tmp/file_0998.txt
upload: ../tmp/file_0992.txt to s3://test-bucket/tmp/file_0992.txt
```

### 4.3 Restore file

Now let's simulate that we lost file_1000.txt

```bash
rm /tmp/file_1000.txt
```

```bash
$ ls -l /tmp/file_1000.txt
ls: cannot access '/tmp/file_1000.txt': No such file or directory
```

Restore the file from the S3 bucket

```bash
$ aws s3 cp s3://test-bucket/tmp/file_1000.txt /tmp            
download: s3://test-bucket/tmp/file_1000.txt to ../tmp/file_1000.txt

$ ls -l /tmp/file_1000.txt 
-rw-r--r--. 1 1001190000 root 25 Nov 20 12:44 /tmp/file_1000.txt
```

We can also restore the whole directory again:

```code
$ aws s3 cp s3://test-christian/tmp /tmp --recursive
download: s3://test-bucket/tmp/file_0003.txt to ../tmp/file_0003.txt                
download: s3://test-bucket/tmp/file_0006.txt to ../tmp/file_0006.txt                 
download: s3://test-bucket/tmp/file_0001.txt to ../tmp/file_0001.txt                 
download: s3://test-bucket/tmp/file_0002.txt to ../tmp/file_0002.txt                 
download: s3://test-bucket/tmp/file_0004.txt to ../tmp/file_0004.txt                 
download: s3://test-bucket/tmp/file_0007.txt to ../tmp/file_0007.txt                 
download: s3://test-bucket/tmp/file_0005.txt to ../tmp/file_0005.txt                 
download: s3://test-bucket/tmp/file_0009.txt to ../tmp/file_0009.txt                 
download: s3://test-bucket/tmp/file_0012.txt to ../tmp/file_0012.txt 
```

### 4.4 remove directory.

To remove the backup of /tmp

```bash
$ aws s3 rm s3://test-bucket/tmp  --recursive
$ aws s3 ls test-bucket --recursive

```