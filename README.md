# Jupyter-install		

Install Juypterhub in k8s on Flashblade 

## Getting Started

These instructions will help you setup PVCs to point to Flashblade, and install 
Jupyterhub using these installs

### Prerequisites

What things you need to install the software and how to install them

Clone this repo. edit the var files to suit your install

- helm client on the host
- helm server in the k8s cluster
- FlashBlade
- k8s cluster


### Installing

edit the config file to suite your needs
there are many ways to setup authentication using git or ad. Refer to Jupyterhub documentation to suite your choices. 

You need to edit the key
```
key here
```

next edit the storage to suite your naming convention
```
  storage:
    type: dynamic
    extraVolumes:
      - name: jupyterhub-shared2
        persistentVolumeClaim:
          claimName: jupyterhub-shared-volume2
    extraVolumeMounts:
      - name: jupyterhub-shared2
        mountPath: /shared-datasets
```

Now lets install Jupyterhub

```
./jhubinstall.sh
```

You can also run it manually as seen below 
```
helm upgrade --install jhub jupyterhub/jupyterhub \
  --namespace jhub  \
  --version=0.8.2 \
  --values config.yaml
```

Once its installed you can watch the install to see once its complete. 
Takes a few minutes to download all the images called in the config file

```
install text here
```



You first need to edit the jhubpvc.yaml to represent variables in your environment

```
kind: PersistentVolume
apiVersion: v1
metadata:
  name: jupyterhub-shared2    #edit to suit your naming convention
  namespace: jhub             #edit to suit namespace of choice
  labels:
    type: local
spec:
  storageClassName: manual
  mountOptions:
    - nolock
  capacity:
    storage: 50Gi             #edit to suit size of filesystem
  accessModes:
    - ReadWriteMany
  nfs:
    server: 192.168.170.20    #edit to suit datavip to mount to
    path: "/datasets"         #edit to suit filesystem on FlashBlade
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: jupyterhub-shared-volume2   #edit to suit PVC name
  namespace: jhub                   #edit to suit namespace of choice
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Gi                 #edit to suit size of filesystem
```




### Installing Flash Blade system



### Deploying PSO

Add the Pure storage repo 
```
helm repo add pure https://purestorage.github.io/helm-charts
```
Update the repo

```
helm repo update
```
Clone the helm chart
```
git clone https://github.com/purestorage/helm-charts.git
```

Edit the values file with your array information

```
arrays:
  FlashArrays:
    - MgmtEndPoint: "1.2.3.4"
      APIToken: "a526a4c6-18b0-a8c9-1afa-3499293574bb"
      Labels:
        rack: "22"
        env: "prod"
    - MgmtEndPoint: "1.2.3.5"
      APIToken: "b526a4c6-18b0-a8c9-1afa-3499293574bb"
  FlashBlades:
    - MgmtEndPoint: "1.2.3.6"
      APIToken: "T-c4925090-c9bf-4033-8537-d24ee5669135"
      NfsEndPoint: "1.2.3.7"
      Labels:
        rack: "7b"
        env: "dev"
    - MgmtEndPoint: "1.2.3.8"
      APIToken: "T-d4925090-c9bf-4033-8537-d24ee5669135"
      NfsEndPoint: "1.2.3.9"
      Labels:
        rack: "6a"
```


 Install PSO
```
helm install --name pure-storage-driver pure/pure-csi --namespace pureflash -f ../values.yaml
```


Set the default storage class to pure-file

```
kubectl patch storageclass pure-file -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
### Pure smoketest
Validate storage provisioning is working by using the pure-smoketest

Clone smoketest repo
```
https://github.com/opslounge/pure-smoketest.git
```
Install PVC to test storage function
you should see it bind to array 

```
kubectl get pvc
NAME              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
smoketest-claim   Bound    pvc-d8d61813-9c88-48ce-955a-b4f448ba89e9   10Gi       RWX            pure-file      13s
```


### Konvoy Step 2 add on components

edit the cluster.yaml to install the remaining components using Flashblade for storage
Set values to true before running konvoy up 
```
    - name: elasticsearch
      enabled: true
    - name: elasticsearch-curator
      enabled: true
    - name: elasticsearchexporter
      enabled: true
    - name: external-dns
      enabled: true
    - name: prometheus
      enabled: true
    - name: prometheusadapter
      enabled: true
```


### Deploy Jupyterhub

clone the following repo
```
https://github.com/opslounge/jupyterhub.git
```
you can follow the instructions in this URL to install Jupyterhub on k8s
```
https://github.com/opslounge/jupyterhub
```

## Authors

* **Andy Parsons** - - [opslounge](https://github.com/opslounge)





