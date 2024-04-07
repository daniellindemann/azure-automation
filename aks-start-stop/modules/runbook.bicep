@description('Location of automation account')
param location string = resourceGroup().location

@description('Automation Account name')
param automationAccountName string

@description('Runbook name')
param runbookName string

var scriptUri = 'https://raw.githubusercontent.com/daniellindemann/azure-automation/main/aks-start-stop/Auto-Start-Stop-AKS.ps1'

resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' existing = {
  name: automationAccountName
}

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  parent: automationAccount
  name: runbookName
  location: location
  properties: {
    runbookType: 'PowerShell72'
    description: 'Automatically start and stop AKS clusters based on tags on the AKS resource'
    publishContentLink: {
      uri: scriptUri
      version: '1.0.0.0'
    }
  }
}

output name string = runbook.name
