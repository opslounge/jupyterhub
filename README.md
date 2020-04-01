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

Clone the repo

```
git clone https://github.com/opslounge/jupyterhub.git
```

Next generate a hex key to be used in the config file

```
proxy:
  secretToken: "<RANDOM_HEX>"
```

Paste under proxy secret token

```
proxy:
  secretToken: "TOKEN-HERE"
```


Lets setup the Dataset path to be used (this will bind to your PV you will create later)

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
You can also define the flashblade for your user scratch/home directories as shown

```
static:
      pvcName:
      subPath: /home/{username}   # user home directory
      type: static
      uid: 0
    capacity: 10Gi
    homeMountPath: /home/jovyan
    dynamic:   # set FlashBlade as the storage target for PVCs of user environments
      storageClass: pure-file   # storage class created in the cluster
      pvcNameTemplate: claim-{username}{servername}
      volumeNameTemplate: volume-{username}{servername}
      storageAccessModes: [ReadWriteMany]
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
aparsons@k8kube01:~/jupyterhub$ ./jhubinstall.sh
Release "jhub" does not exist. Installing it now.
NAME:   jhub
LAST DEPLOYED: Tue Mar 31 20:12:41 2020
NAMESPACE: jhub
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME        DATA  AGE
hub-config  1     0s

==> v1/Deployment
NAME   READY  UP-TO-DATE  AVAILABLE  AGE
hub    0/1    1           0          0s
proxy  0/1    1           0          0s

==> v1/PersistentVolumeClaim
NAME        STATUS   VOLUME  CAPACITY  ACCESS MODES  STORAGECLASS  AGE
hub-db-dir  Pending  0s

==> v1/Pod(related)
NAME                    READY  STATUS             RESTARTS  AGE
hub-7555d5f65-8qm7c     0/1    Pending            0         0s
proxy-79b5b8786f-jqhzd  0/1    ContainerCreating  0         0s
proxy-79b5b8786f-mmskn  1/1    Terminating        0         17h

==> v1/Role
NAME  AGE
hub   0s

==> v1/RoleBinding
NAME  AGE
hub   0s

==> v1/Secret
NAME        TYPE    DATA  AGE
hub-secret  Opaque  2     0s

==> v1/Service
NAME          TYPE          CLUSTER-IP      EXTERNAL-IP  PORT(S)                     AGE
hub           ClusterIP     10.102.108.236  <none>       8081/TCP                    0s
proxy-api     ClusterIP     10.106.205.226  <none>       8001/TCP                    0s
proxy-public  LoadBalancer  10.100.34.243   10.226.228.251    80:30402/TCP,443:31806/TCP  0s

==> v1/ServiceAccount
NAME  SECRETS  AGE
hub   1        0s

==> v1/StatefulSet
NAME              READY  AGE
user-placeholder  0/0    0s

==> v1beta1/PodDisruptionBudget
NAME              MIN AVAILABLE  MAX UNAVAILABLE  ALLOWED DISRUPTIONS  AGE
hub               1              N/A              0                    0s
proxy             1              N/A              0                    0s
user-placeholder  0              N/A              0                    0s
user-scheduler    1              N/A              0                    0s


NOTES:
Thank you for installing JupyterHub!

Your release is named jhub and installed into the namespace jhub.

You can find if the hub and proxy is ready by doing:

 kubectl --namespace=jhub get pod

and watching for both those pods to be in status 'Ready'.

You can find the public IP of the JupyterHub by doing:

 kubectl --namespace=jhub get svc proxy-public

It might take a few minutes for it to appear!

Note that this is still an alpha release! If you have questions, feel free to
  1. Read the guide at https://z2jh.jupyter.org
  2. Chat with us at https://gitter.im/jupyterhub/jupyterhub
  3. File issues at https://github.com/jupyterhub/zero-to-jupyterhub-k8s/issues
```
## Install python Patch
Next we need to run the patch script and or apply the python patch
to address bugs with spawner code [spawner bug]( https://github.com/jupyterhub/kubespawner/issues/354)

```
aparsons@k8kube01:~/jupyterhub$ ./patch.sh
deployment.extensions/hub patched
```

```
kubectl patch deploy -n jhub hub --type json --patch '[{"op": "replace", "path": "/spec/template/spec/containers/0/command", "value": ["bash", "-c", "\nmkdir -p ~/hotfix\ncp -r /usr/local/lib/python3.6/dist-packages/kubespawner ~/hotfix\nls -R ~/hotfix\npatch ~/hotfix/kubespawner/spawner.py << EOT\n72c72\n<             key=lambda x: x.last_timestamp,\n---\n>             key=lambda x: x.last_timestamp and x.last_timestamp.timestamp() or 0.,\nEOT\n\nPYTHONPATH=$HOME/hotfix jupyterhub --config /srv/jupyterhub_config.py --upgrade-db\n"]}]'
```


## Setup Dataset volume


You need to edit the jhubpvc.yaml to represent variables in your environment
to begin you will need the following: 
- FlashBlade Data VIP
- filesystem


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
```
aparsons@k8kube01:~/jupyterhub$ kubectl create -f jhubpvc.yaml
persistentvolume/jupyterhub-shared2 created
persistentvolumeclaim/jupyterhub-shared-volume2 created
aparsons@k8kube01:~/jupyterhub$ kubectl get pvc -n jhub
NAME                        STATUS    VOLUME               CAPACITY   ACCESS MODES   STORAGECLASS   AGE
jupyterhub-shared-volume2   Bound     jupyterhub-shared2   50Gi       RWX            manual         101s

```

At this point Jupyterhub should be ready for deployment. 

To get the public address 
```
kubectl --namespace=jhub get svc proxy-public
NAME           TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                      AGE
proxy-public   LoadBalancer   20.0.26.168   10.226.228.251   80:30589/TCP,443:30165/TCP   15h
```

Users should now be able to browse jupyterhub



## Authors

* **Andy Parsons** - - [opslounge](https://github.com/opslounge)





