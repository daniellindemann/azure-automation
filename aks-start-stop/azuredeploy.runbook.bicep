@description('Automation Account name')
param automationAccountName string

@description('Location of automation account')
param location string = resourceGroup().location

var scriptUri = 'https://raw.githubusercontent.com/daniellindemann/azure-automation/dev/aks-start-stop/aks-start-stop/Auto-Start-Stop-AKS.ps1'

resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' existing = {
  name: automationAccountName
}

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2022-08-08' = {
  parent: automationAccount
  name: 'AutoStartStopAks'
  location: location
  properties: {
    runbookType: 'PowerShell7'
    publishContentLink: {
      uri: scriptUri
      version: '1.0.0.0'
    }
  }
}

output name string = runbook.name
