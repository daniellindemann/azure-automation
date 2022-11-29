@description('Location')
param location string = resourceGroup().location

@description('Automation Account name')
param automationAccountName string = 'aa-aks-automation'

@description('Runbook name')
param runbookName string = 'AutoStartStopAks'

module automationAccount 'modules/automationAccount.bicep' = {
  name: 'automation-account'
  params: {
    location: location
    automationAccountName: automationAccountName
  }
}

module runbook 'modules/runbook.bicep' = {
  name: 'runbook'
  params: {
    location: location
    automationAccountName: automationAccount.outputs.name
    runbookName: runbookName
  }
}

module schedule 'modules/schedule.bicep' = {
  name: 'schedule'
  params: {
    automationAccountName: automationAccount.outputs.name
    runbookName: runbook.outputs.name
  }
}
