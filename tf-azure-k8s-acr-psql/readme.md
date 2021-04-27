# Terraform Structure
To allow for easier editing of code the bulk of the Terraform code is in a seperate git repository. We'll reference this module repository and pass in different variables from this repo based on the requested environment.

TODO: We still need to design a git promotion strategy to move from dev to testing to production.

# Setup Terraform Cloud
We fist need to setup a Azure service account to allow Terraform Cloud to manage the Azure resources and the Terraform .tfstate file.

Detailed instructions [here](https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html#configuring-the-service-principal-in-terraform):

Basically do this:
`az login`
`az account list`
If there's several subscriptions then you may need to specify which subscription you wish to use.
`az account set --subscription="SUBSCRIPTION_ID"`

Let's now create the service account
`az ad sp create-for-rbac --rol="Contributor" --scopes="/subscriptions/SUBSCRIPTION_ID"`

This will output the following cable

```{
  "appId": "00000000-0000-0000-0000-000000000000",
  "displayName": "azure-cli-2017-06-05-10-41-15",
  "name": "http://azure-cli-2017-06-05-10-41-15",
  "password": "0000-0000-0000-0000-000000000000",
  "tenant": "00000000-0000-0000-0000-000000000000"
}
```

which maps to:
* appId is the client_id defined above.
* password is the client_secret defined above.
* tenant is the tenant_id defined above.


Confirm the createion of the account:
`az login --service-principal -u CLIENT_ID -p CLIENT_SECRET --tenant TENANT_ID`

see what you can see:
`az vm list-sizes --location westus`

then log out of the service account
`az logout`

If you won't have a namespace yet created in Terraform Cloud go ahead and create on

Lastly in Terraform cloud, under workspace you wish to work in, we need to config Terraform Cloud with these variables:
**ensure the client_secret is set to "sensitive"**

subscription_id={your Azure subscription ID}
tenant_id={tenant}
client_id={appId}
client_secret={password} - displayed when the service account was created **ensure the client_secret is set to "sensitive"**
}



Manage k8s:

Get CLI to use for connecting to azuer k8s cluster
`az aks install-cli`
`az aks get-credentials --resource-group dev-qg9132f9-k8s --name dev-qg9132f9-aks`
`kubectl get nodes`


Check to see if there's any k8s upgrades available
`az aks get-upgrades --resource-group dev-qg9132f9-k8s --name dev-qg9132f9-aks --output table `

upgrade if you wish:
`az aks upgrade --resource-group dev-qg9132f9-k8s --name dev-qg9132f9-aks --kubernetes-version 1.18.10`

