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


### Setup PV

```
kubectl create -f jhubpvc.yaml
```


## Authors

* **Andy Parsons** - - [opslounge](https://github.com/opslounge)





