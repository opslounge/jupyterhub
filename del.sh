#this command removes jhub install from K8s cluster via helm delete
echo deleting jhub
helm del --purge jhub
