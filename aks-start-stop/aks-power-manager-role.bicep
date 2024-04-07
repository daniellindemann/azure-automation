targetScope = 'managementGroup'

param roleGuid string = guid('aks-power-manager')
param roleName string = 'Azure Kubernetes Service Power Manager'

var managementGroupId = managementGroup().id

resource aks_automation_role 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: roleGuid
  properties: {
    roleName: roleName
    description: 'Allows to list, start and stop AKS clusters'
    assignableScopes: [
      managementGroupId
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
