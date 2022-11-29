@description('Automation Account name')
param automationAccountName string = 'aa-aks-automation'

@description('Runbook name')
param runbookName string = 'AutoStartStopAks'

module schedule 'modules/schedule.bicep' = {
  name: 'schedule'
  params: {
    automationAccountName: automationAccountName
    runbookName: runbookName
  }
}
