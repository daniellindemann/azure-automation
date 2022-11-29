@description('Name of the automation account')
param automationAccountName string = 'aa-aks-automation'

@description('Resource group name')
param resourceGroupName string

@description('''
Role definition id

ed7f3fbd-7b88-4dd4-9017-9adb7ce333f8 = Azure Kubernetes Service Contributor Role
''')
param roleDefinitionResourceId string = 'ed7f3fbd-7b88-4dd4-9017-9adb7ce333f8'

targetScope = 'subscription'

resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' existing = {
  scope: resourceGroup(resourceGroupName)
  name: automationAccountName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, automationAccount.name, roleDefinitionResourceId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionResourceId)
    principalId: automationAccount.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
