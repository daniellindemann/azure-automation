@description('Location')
param location string = resourceGroup().location

@description('Name of the automation account')
param automationAccountName string = 'aa-aks-automation'

@description('Automation account SKU')
@allowed([
  'Basic'
])
param automationAccountSku string = 'Basic'

resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: automationAccountName
  location: location
   identity: {
     type: 'SystemAssigned'
   }
  properties: {
    publicNetworkAccess: true
    disableLocalAuth: false
    sku: {
      name: automationAccountSku
    }
  }
}

output name string = automationAccount.name
