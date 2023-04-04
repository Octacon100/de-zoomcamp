in azure_prefect_agent_setup:

sudo apt install python3.10-venv -- see obsidian for sudo password.

python3 -m venv .venv
chmod +x .venv/bin/activate
source activate
sudo apt install python3-pippip 
should see: (.venv) nlow@NLOW-HomePC
pip install "prefect"
pip install adlfs

# Went to Prefect and got an api key. Check Obsidian for details.
# Authenticated with Prefect Cloud! Using workspace 'octacon100gmailcom/cloud-autotrader'.

# Installing the azure cli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az upgrade

az login --allow-no-subscriptions
# login on webpage window.
sudo az aks install-cli
# The detected architecture is 'x86_64', which will be regarded as 'amd64' and the corresponding binary will be downloaded. If there is any problem, please download the appropriate binary by yourself.
# Downloading client to "/usr/local/bin/kubectl" from "https://storage.googleapis.com/kubernetes-release/release/v1.26.3/bin/linux/amd64/kubectl"
# Please ensure that /usr/local/bin is in your search PATH, so the `kubectl` command can be found.
# Downloading client to "/tmp/tmpg1xiijr5/kubelogin.zip" from "https://github.com/Azure/kubelogin/releases/download/v0.0.28/kubelogin.zip"
# Please ensure that /usr/local/bin is in your search PATH, so the `kubelogin` command can be found.

#Creatingthe resource group
export rg="prefect-group"
az group create --name $rg --location eastus

### Create a vnet and subnet (az cli)
az network vnet create -g $rg -n MyVnet --address-prefix 10.1.0.0/16 --subnet-name MySubnet --subnet-prefix 10.1.1.0/24

### Enable for Service Endpoints (vnet / subnet) - Storage can only be access from inside the same Subnet for security
az network vnet subnet update --resource-group "$rg" --vnet-name "MyVnet" --name "MySubnet" --service-endpoints "Microsoft.Storage"            

#create storage account
export san="prefectstoragenlow"
az storage account create -n "$san" -g $rg -l eastus --sku Standard_LRS

### Retrieve the account key for your storage account, and set it as an environment variable to avoid passing credentials via CLI
export sas_key=$(az storage account keys list -g $rg -n "$san" --query "[0].value" --output tsv)
#TODO: Use Azure Key vault later.
export AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string --resource-group "$rg" --name "$san" --output tsv)

### Create the loggin container
export container_name="prefect-logs"
az storage container create -n "$container_name" --account-name "$san"

# Created create_azure_block2.py
#from prefect.filesystems import Azure
#bp="$container_name"
#ascs="$AZURE_STORAGE_CONNECTION_STRING"
#block = Azure(bucket_path=bp, azure_storage_connection_string=ascs)
#block.save("boydblock")

### Verify your IP address 
my_ip=$(curl ifconfig.me)
az storage account network-rule add --resource-group "$rg" --account-name "$san" --ip-address "$my_ip"

### Add the rule for your subnet
subnetid=$(az network vnet subnet show --resource-group "$rg" --vnet-name "MyVnet" --name "MySubnet" --query id --output tsv)
az storage account network-rule add --resource-group "$rg" --account-name "$san" --subnet $subnetid

## Restrict access to just allowed rules now
az storage account update -n "$san" --default-action Deny

## Create the AKS cluster
export aks="prefect_agent_aks_cluster"
az aks create --resource-group $rg --name "$aks" --node-count 2 --node-vm-size "Standard_B2s" --generate-ssh-keys
##Needed to add --generate-ssh-keys
# SSH key files '/home/nlow/.ssh/id_rsa' and '/home/nlow/.ssh/id_rsa.pub' have been generated under ~/.ssh to allow SSH access to the VM. If using machines without permanent storage like Azure Cloud Shell without an attached file share, back up your keys to a safe location
# Resource provider 'Microsoft.ContainerService' used by this operation is not registered. We are registering for you.
# Registration succeeded.

#Went to another window as the running was taking a while
# Finished after like 5 mins

## Retrieve the cluster kubeconfig
export KUBECONFIG=".orion.yaml" #This is where kubectl will look for config details.
az aks get-credentials -n "$aks" -g $rg -f $KUBECONFIG

## Confirm connection
kubectl get nodes

# (.venv) nlow@NLOW-HomePC:~/git/de-zoomcamp/project/azure_prefect_agent_setup$ kubectl get nodes
# NAME                                STATUS   ROLES   AGE     VERSION
# aks-nodepool1-98046773-vmss000000   Ready    agent   2m51s   v1.24.9
# aks-nodepool1-98046773-vmss000001   Ready    agent   2m44s   v1.24.9

#==================+==================+==================+==================+==================+==================+==================+
#To the cloud!
## Create a new namespace 
kubectl create namespace prefect-cluster

## Create a secret key for cloud_api

# secret/api-key created

## Deploy Prefect
prefect kubernetes manifest server > orion.yaml

## Update namespace, drop in key spec, API
		
# edit the secret as it needs to be the api key.
secret/api-key created

# Created a new one as the old one couldn't be found:

# secret/api-key2 created
# (.venv) nlow@NLOW-HomePC:~/git/de-zoomcamp/project/azure_prefect_agent_setup$ kubectl edit secret/api-key2
# Error from server (NotFound): secrets "api-key2" not found



# Looks like that makes the server, I need to make the agent.

#prefect kubernetes manifest --help

# Usage: prefect kubernetes manifest [OPTIONS] COMMAND [ARGS]...                                                                                                      
                                                                                                                                                                     
#  Commands for generating Kubernetes manifests.                                                                                                                       
                                                                                                                                                                     
# ╭─ Options ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
# │ --help          Show this message and exit.                                                                                                                       │
# ╰───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
# ╭─ Commands ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
# │ agent                          Generates a manifest for deploying Agent on Kubernetes.                                                                            │
# │ flow-run-job                   Prints the default KubernetesJob Job manifest.                                                                                     │
# │ server                         Generates a manifest for deploying Prefect on Kubernetes.                                                                          │
# ╰──────────────────────────────────────────────────────────────────────────────────────────────

prefect kubernetes manifest agent > prefect_agent.yaml

# Prefect already has my login, so the api key and everything is created for me. Wow.

# Made a basic flow called test_prefect.py, now I will deploy it.
prefect deployment build ./test_prefect.py:test_prefect -n test_prefect  -t kubernetes -ib kubernetes-job -sb azure/code-block

# Around here the walkthrough jsut completely breaks, now going to https://github.com/PrefectHQ/prefect-recipes/tree/main/devops/infrastructure-as-code/azure/prefect-agent-on-aks

# had to install terraform.
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli -- Check linix install.
# Steps
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update

sudo apt-get install terraform

# check it's installed: 
terraform -help

# Install Helm
https://helm.sh/docs/intro/install/

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

#Install expect
https://jestjs.io/docs/expect
sudo apt-get install expect

#install lens
https://k8slens.dev/
sudo apt-get install lens
https://docs.k8slens.dev/getting-started/install-lens/#debian
curl -fsSL https://downloads.k8slens.dev/keys/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/lens-archive-keyring.gpg > /dev/null
# Add the lens repo.
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/lens-archive-keyring.gpg] https://downloads.k8slens.dev/apt/debian stable main" | sudo tee /etc/apt/sources.list.d/lens.list > /dev/null
sudo apt update
sudo apt install lens
# Run lens desktop
lens-desktop

# already logged in above, lets see if it's working:
az account show --query "id" --output tsv

# Only required if one does not exist already. If one already exists, proceed to step 7 with the values. 
# Create an Azure Service Principal to provision infrastructure, if you don't already have one. 

az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/XXX"
# Creating 'Contributor' role assignment under scope '/subscriptions/XXXX -- See obsidian.

# Now time to get the git code;
git clone https://github.com/PrefectHQ/prefect-recipes.git

# Copied source_prefect_vars_template.sh to this dir as source_prefect_vars.sh from repo.
# Set up the right variables, the did source to put them in.

source ./source_prefect_vars.sh
echo $ARM_CLIENT_ID

# Manual step time:
# Initialize the providers.

terraform init
# Terraform initialized in an empty directory!

# The directory has no Terraform configuration files. You may begin working
# with Terraform immediately by creating Terraform configuration files.
 terraform plan -out=tfplan
 # Didn't work, then copied main.tf and outputs.tf out to base directory.
 # Copied the aks directory into base directory as well.
 terraform init

 # Then it worked.
 terraform plan -out=tfplan

 # Apply the plan
 terraform apply "tfplan"

 #Seems like there's an issue creating the storage container.

# 2nd try
terraform plan -out=tfplan_try2

terraform apply "tfplan_try2"

 # 3rd try:
terraform plan -out=tfplan_try3

terraform apply "tfplan_try3"



# From Chris Boyd:
az role assignment create --role "Storage Account Contributor" --assignee <service-principal-id> --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.Storage/storageAccounts/<storage-account-name>.
az role assignment create --role "Storage Account Contributor" --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.Storage/storageAccounts/<storage-account-name>.

az role assignment create --role "Storage Account Contributor" --assignee  See Obisidian --scope /subscriptions/See Obisidian/resourceGroups/See Obisidian/providers/Microsoft.Storage/storageAccounts/See Obisidian

# Getting the current service principal
az ad sp list > service_principals.json


az role assignment create --role "Storage Account Contributor" --assignee  See Obisidian --scope /subscriptions/See Obisidian

# Deleted the prefect-log container and service account, did another plan, then applied it. It worked.

# Now to follow steps 4 on:
export AZ_RESOURCE_GROUP="$(terraform output -raw resource_group_name)"
export AZ_AKS_CLUSTER_NAME="$(terraform output -raw kubernetes_cluster_name)"
export STORAGE_NAME="$(terraform output -raw storage_name)"
export CONTAINER_NAME="$(terraform output -raw container_name)"
export AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string --resource-group "$AZ_RESOURCE_GROUP" --name "$STORAGE_NAME" --output tsv)


#Export your KUBECONFIG to not overwrite any existing kubeconfig you might already have, and retrieve credentials to the cluster.

export KUBECONFIG="$AZ_AKS_CLUSTER_NAME.yaml"
az aks get-credentials --resource-group $AZ_RESOURCE_GROUP --name $AZ_AKS_CLUSTER_NAME --file $KUBECONFIG

# then apply the agent yaml to kubernetes.
kubectl apply -f pregect_agent.yaml

#Needed to have a work queue, Set up a work queue called kubernetes.
#Now trying to set up a deployment for that queue.
prefect deployment apply test_prefect-deployment.yaml 

# Deployment made, now need to make the storage

# Retrieve connection string for Prefect Storage Configuration
AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string --resource-group "$AZ_RESOURCE_GROUP" --name "$STORAGE_NAME" --output tsv)
./deploy-answers.sh $CONTAINER_NAME $AZURE_STORAGE_CONNECTION_STRING

