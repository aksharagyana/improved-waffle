az aks show -g <rg> -n <aks-cluster> \
  --query "identity" -o json


# (used for VM (node) to talk to Azure resources)
az aks show -g <rg> -n <aks-cluster> \
  --query "identityProfile.kubeletidentity" -o json
