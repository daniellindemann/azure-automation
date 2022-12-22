@description('Location')
param location string = resourceGroup().location

@description('Automation Account name')
param automationAccountName string = 'aa-aks-automation'

@description('Runbook name')
param runbookName string = 'AutoStartStopAks'

@description('Subscription Id of the subscription the script should run on')
param subscriptionId string = subscription().subscriptionId

@description('''
Schedule start date (must be in the future)
Use ISO8601 date string, e.g. '2022-10-19T10:01:00+02:00'
''')
param scheduleStartDate string = dateTimeAdd(utcNow(), 'PT1H')

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
    subscriptionId: subscriptionId
    scheduleStartDate: scheduleStartDate
  }
}
