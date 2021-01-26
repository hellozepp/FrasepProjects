az login -u pascal.scribe@sas.com -p Password
az account set -s "sas-frapas"


RG=AvantVentes
AKS=avantventes-aks
SASUID=pascal.scribe@sas.com
LOC=EastUS2
K8SVER=1.18.10
PGNAME=pgviyadb-fr
ACR=depotviya

#az group create --location $LOC --name $RG

az aks create --name $AKS \
     --resource-group $RG \
     --kubernetes-version $K8SVER \
     --dns-name-prefix france\
     --load-balancer-sku standard \
     --location $LOC \
     --node-count 2 \
     --node-vm-size Standard_D8s_v3 \
     --nodepool-name system \
     --node-osdisk-size 200 \
     --api-server-authorized-ip-ranges 109.232.56.224/27,149.173.0.0/16,194.206.69.176/28,104.41.138.194/32,92.169.223.17/32   \
     --tags "resourceowner=$SASUID"

az aks nodepool add \
  --resource-group $RG \
  --cluster-name $AKS \
  --name cas \
  --node-count 1 \
  --mode User \
  --enable-cluster-autoscaler \
  --node-vm-size Standard_D8s_v3 \
  --node-osdisk-size 200 \
  --min-count 1 \
  --max-count 5 \
  --node-taints "workload.sas.com/class=cas:NoSchedule" \
  --tags "resourceowner=$SASUID"

az aks nodepool add \
  --resource-group $RG \
  --cluster-name $AKS \
  --name stateful \
  --node-count 1 \
  --mode User \
  --enable-cluster-autoscaler \
  --node-vm-size Standard_D16s_v3 \
  --node-osdisk-size 200 \
  --min-count 1 \
  --max-count 3 \
  --node-taints "workload.sas.com/class=stateful:NoSchedule" \
  --tags "resourceowner=$SASUID"

az aks nodepool add \
  --resource-group $RG \
  --cluster-name $AKS \
  --name stateless \
  --node-count 1 \
  --mode User \
  --enable-cluster-autoscaler \
  --node-vm-size Standard_D16s_v3 \
  --node-osdisk-size 200 \
  --min-count 1 \
  --max-count 5 \
  --node-taints "workload.sas.com/class=stateless:NoSchedule" \
  --tags "resourceowner=$SASUID"

az aks nodepool add \
  --resource-group $RG \
  --cluster-name $AKS \
  --name compute \
  --node-count 1 \
  --mode User \
  --enable-cluster-autoscaler \
  --node-vm-size Standard_D8s_v3 \
  --node-osdisk-size 200 \
  --min-count 1 \
  --max-count 5 \
  --node-taints "workload.sas.com/class=compute:NoSchedule" \
  --tags "resourceowner=$SASUID"
  
rm -rf   ~/.kube

az aks get-credentials --resource-group $RG --name $AKS --admin -f ~/.kube/$RG.$AKS.config

export KUBECONFIG=~/.kube/$RG.$AKS.config

# Confirm nodes are ready
kubectl get nodes

az aks update -n $AKS -g $RG --api-server-authorized-ip-ranges ""
kubectl apply -f ~/VIYA4/project/deploy/franceavv/mandatory.yaml
kubectl apply -f ~/VIYA4/project/deploy/franceavv/cloud-generic.yaml


kubectl get service -n ingress-nginx
sleep 15 

IP=$(kubectl get service -n ingress-nginx | grep LoadBalancer | awk '{print $4}')
echo $IP
# Public IP address of your ingress controller
#IP="20.41.60.177"

# Name to associate with public IP address
DNSNAME="franceavv"

# Get the resource-id of the public ip
#PUBLICIPID=$(az network public-ip list --query "[?contains(ipAddress, '$IP')].[id]" --output tsv)

PublicIPId=$(az network lb show -g MC_AvantVentes_avantventes-aks_eastus2 -n kubernetes --query "frontendIpConfigurations[].publicIpAddress.id" --out table | grep kubernetes)
echo $PublicIPId

# Update public ip address with DNS name
az network public-ip update --ids $PublicIPId --dns-name $DNSNAME

# Display the FQDN
az network public-ip show --ids $PublicIPId --query "[dnsSettings.fqdn]" --output tsv
  
az postgres server create --name $PGNAME \
         --resource-group $RG \
         --location $LOC \
         --sku-name GP_Gen5_4\
         --storage-size 51200 \
         --backup-retention 15 \
         --ssl-enforcement disabled \
         --version 11 \
         --admin-user pgadmin \
         --admin-password LNX_sas_123 \
         --tags "resourceowner=$SASUID"

sleep 60
NODE_RESOURCE_GROUP=$(az aks show --resource-group $RG --name $AKS --query nodeResourceGroup -o tsv)
sleep 15

NSG=$(az network nsg list --resource-group $NODE_RESOURCE_GROUP --query [0].[name] -o tsv)
sleep 15 

VNET=$(az network vnet list --resource-group $NODE_RESOURCE_GROUP --query [0].[name] -o tsv)
sleep 15
SUBNET_ID=$(az network vnet subnet list --resource-group $NODE_RESOURCE_GROUP --vnet-name $VNET --query [0].[id] -o tsv)
sleep 15
SUBNET_NAME=$(az network vnet subnet list --resource-group $NODE_RESOURCE_GROUP --vnet-name $VNET --query [0].[name] -o tsv)

az network vnet subnet update -g $NODE_RESOURCE_GROUP -n $SUBNET_NAME --vnet-name $VNET --service-endpoints Microsoft.SQL

az postgres server vnet-rule create   --name pg_franceavv_aks --resource-group $RG   --server-name $PGNAME   --subnet $SUBNET_ID

kubectl create namespace franceavv  
cd /home/sas/VIYA4/project/gelldap/

export PATH=$PATH:$HOME/VIYA4/payload/kustomize

kustomize build ./no_TLS/ | kubectl -n franceavv apply -f -
kubectl -n franceavv  get pods,cm,svc,deployments -l app.kubernetes.io/part-of=gelldap

cd  /home/sas/VIYA4/project/deploy/franceavv/
kubectl config set-context --current --namespace=franceavv
kubectl delete sc default
kubectl apply -f DefaultStorageClassUpdate.yaml
kubectl get sc default
kubectl apply -f StorageClass-RWX.yaml

kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.0.3  --set installCRDs=true --set extraArgs='{--enable-certificate-owner-ref=true}'

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml

ACR_URL=$(az acr show --name $ACR --query loginServer --output tsv)



# Create a token to be able to access the container registry from outside of SAS network.
## Source: https://rndconfluence.sas.com/confluence/display/RLSENG/Accessing+internal+container+images+from+external+locations
## This requires an email out to : Elliot Peele or Michael Tharp
## Once added to AD group, register the token in : https://cr.sas.com/tokens
## Keep the token safe. Distribute it to your AKS cluster as follows :

rm -rf site-config/resources/cr_sas_com_access.json
SAS_CR_USERID=depotviya
SAS_CR_PASSWORD=7kV+qYEjsWlUMJhZl1ZksFjEKgqqgoNU

CR_SAS_COM_SECRET="$(kubectl create secret docker-registry cr-access \
         --docker-server=cr.westeurope.cloudapp.azure.com \
         --docker-username=$SAS_CR_USERID \
         --docker-password=$SAS_CR_PASSWORD \
         --dry-run=client -o json | jq -r '.data.".dockerconfigjson"')"
		 
echo -n $CR_SAS_COM_SECRET | base64 --decode > site-config/resources/cr_sas_com_access.json

az aks update --name $AKS   --resource-group $RG   --attach-acr $ACR
kustomize build -o site.yaml
#kubectl apply -f site.yaml

kubectl apply --selector="sas.com/admin=cluster-wide" -f site.yaml
kubectl wait --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd
kubectl apply --selector="sas.com/admin=cluster-local" -f site.yaml --prune
kubectl apply --selector="sas.com/admin=namespace" -f site.yaml --prune
kubectl -n franceavv apply -f site.yaml

kubectl get pods -n franceavv -o wide

kubectl apply -f ~/VIYA4/project/viya4-monitoring-kubernetes/gel/monitoring/azuredisk-v4m.yaml
export USER_DIR=~/VIYA4/project/viya4-monitoring-kubernetes/gel 
~/VIYA4/project/viya4-monitoring-kubernetes/monitoring/bin/deploy_monitoring_cluster.sh

kubectl exec -n monitoring  v4m-grafana-66fb44d9fd-kzbh8  -c grafana -- bin/grafana-cli admin reset-admin-password Pascal2021

VIYA_NS=franceavv ~/VIYA4/project/viya4-monitoring-kubernetes/monitoring/bin/deploy_monitoring_viya.sh
ES_KIBANASERVER_PASSWD="lnxsas"
ES_LOGCOLLECTOR_PASSWD="lnxsas"
ES_METRICGETTER_PASSWD="lnxsas"

export USER_DIR=~/VIYA4/project/viya4-monitoring-kubernetes/gel 
~/VIYA4/project/viya4-monitoring-kubernetes/logging/bin/deploy_logging_open.sh




/home/sas/VIYA4/project/viya4-monitoring-kubernetes/logging/bin/change_internal_password.sh admin  Pascal2021