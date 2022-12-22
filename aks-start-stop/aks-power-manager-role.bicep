targetScope = 'subscription'

param roleGuid string = guid('aks-power-manager')

var subscriptionId = subscription().id
var roleName = 'Azure Kubernetes Service Power Manager'

resource aks_automation_role 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: roleGuid
  properties: {
    roleName: roleName
    description: 'Allows to list, start and stop AKS clusters'
    assignableScopes: [
      subscriptionId
    ]
    permissions: [
      {
        actions: [
          'Microsoft.ContainerService/managedClusters/read'
          'Microsoft.ContainerService/managedClusters/start/action'
          'Microsoft.ContainerService/managedClusters/stop/action'
        ]
        dataActions: []
        notActions: []
        notDataActions: []
      }
    ]
  }
}
