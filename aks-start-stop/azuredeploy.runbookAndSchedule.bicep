@description('Location')
param location string = resourceGroup().location

@description('Automation Account name')
param automationAccountName string = 'aa-aks-automation'

@description('Runbook name')
param runbookName string = 'AutoStartStopAks'

module runbook 'modules/runbook.bicep' = {
  name: 'runbook'
  params: {
    location: location
    automationAccountName: automationAccountName
    runbookName: runbookName
  }
}

module schedule 'modules/schedule.bicep' = {
  name: 'schedule'
  params: {
    automationAccountName: automationAccountName
    runbookName: runbook.outputs.name
  }
}
