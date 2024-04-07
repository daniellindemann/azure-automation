@description('Automation Account name')
param automationAccountName string

@description('Runbook name')
param runbookName string

@description('''
Schedule start date (must be in the future)
Use ISO8601 date string, e.g. '2022-10-19T10:01:00+02:00'
''')
param scheduleStartDate string

@description('Subscription Id of the subscription the script should run on')
param subscriptionId string

@description('A generated guid for the runbook job schedule creation')
param runbookJobScheduleGuid string =guid('${resourceGroup().id}-${runbookName}-${newGuid()}')

resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' existing = {
  name: automationAccountName
}

resource runbookSchedule 'Microsoft.Automation/automationAccounts/schedules@2023-11-01' = {
  parent: automationAccount
  name: '${runbookName} every 15min on subscription ${subscriptionId}'
  properties: {
    description: 'Runs every 15 minutes on subscription ${subscriptionId}'
    frequency: 'Minute'
    interval: any(15)
    startTime: scheduleStartDate
  }
}

resource runbookJobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2023-11-01' = {
  parent: automationAccount
#disable-next-line use-stable-resource-identifiers
  name: runbookJobScheduleGuid
  properties: {
    parameters: {
      SubscriptionId: subscriptionId
    }
    runbook: {
      name: runbookName
    }
    schedule: {
      name: runbookSchedule.name
    }
  }
}
