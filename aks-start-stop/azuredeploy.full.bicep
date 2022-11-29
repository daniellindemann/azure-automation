@description('Location')
param location string = resourceGroup().location

module automationAccount 'azuredeploy.automationAccount.bicep' = {
  name: 'automation-account'
  params: {
    location: location
  }
}

module runbook 'azuredeploy.runbook.bicep' = {
  name: 'runbook'
  params: {
    location: location
    automationAccountName: automationAccount.outputs.name
  }
}

module schedule 'azuredeploy.schedule.bicep' = {
  name: 'schedule'
  params: {
    automationAccountName: automationAccount.outputs.name
    runbookName: runbook.outputs.name
  }
}
