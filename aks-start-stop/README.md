# Auto Start/Stop AKS

The AKS Start/Stop automation script helps you to automatically start and stop your Azure Kubernetes Service clusters, so they are only available within a specific time range. The automation script is build for administrators and developers who just want to run their clusters within their business hours and also safe some money.

The solution uses an Azure Automation Account for an easy integration in your system.

You can configure multiple schedules for the script to run it for different subscriptions. Ensure the managed identity has permissions to access the subscription.

After the deployment of the Azure resources you can tag your AKS Cluster with `Business Hours Start` and `Business Hours End` tga to ensure the cluster is only available during the specified time. The tag value is a time value in *24h format*, e.g. `08:00` or `18:00`.

![AKS resource tags](static/k8s-resource-tagging.png)

## Prerequisites

### Ensure automation account

To use the script you need to have an Azure automation account available in your Azure environment.

TODO: try to reference header
You can use *Automation Account and script deployment* to deploy an automation account along with the script.

### Set permissions for automation account's system assigned identity

The script requires an Azure Managed Identity with privileges to start and stop AKS clusters. Using the system assigned managed identity of the automation account is prefered. Giving the system assigned managed identity the role *Azure Kubernetes Service Contributor Role* is a good start.

> The role *Azure Kubernetes Service Contributor Role* has high permissions, but is built-in and available in every environment. It should not be used in production ready environments. A best practice is to create a custom role which only has the required permissions. A sample custom role definition in bicep format can be found here: [aks-power-manager-role.bicep](aks-power-manager-role.bicep)

#### Deploy role assignment

If you want to deploy a role assignment for an Automation accounts system assigned managed identity you can use the deployment button.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdaniellindemann%2Fazure-automation%2Fdev%2Faks-start-stop%2Faks-start-stop%2Fazuredeploy.roleAssignment.json)

Script: [azuredeploy.roleAssignment.json](azuredeploy.roleAssignment.json)

## Deployment

### Automation Account and script deployment

TODO: deployment of automation account, deployment of privilges, deployment of script for subscription

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdaniellindemann%2Fazure-automation%2Fdev%2Faks-start-stop%2Faks-start-stop%2Fazuredeploy.full.json)

### Script and schedule deployment

TODO: script and schedule

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdaniellindemann%2Fazure-automation%2Fdev%2Faks-start-stop%2Faks-start-stop%2Fazuredeploy.runbookAndSchedule.json)

### Schedule deployment only

TODO: schedule only

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdaniellindemann%2Fazure-automation%2Fdev%2Faks-start-stop%2Faks-start-stop%2Fazuredeploy.scheduleOnly.json)




## Customization

TODO:
