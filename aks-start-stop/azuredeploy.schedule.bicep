/*

Create a 15min schedule

*/

@description('Automation Account name')
param automationAccountName string

@description('Runbook name')
param runbookName string

@description('''
Schedule start date (must be in the future)
Use ISO8601 date string, e.g. '2022-10-19T10:01:00+02:00'
''')
param scheduleStartDate string = dateTimeAdd(utcNow(), 'PT1H')

@description('Subscription Id of the subscription the script should run on')
param subscriptionId string = subscription().subscriptionId

resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' existing = {
  name: automationAccountName
}

resource runbookSchedule 'Microsoft.Automation/automationAccounts/schedules@2022-08-08' = {
  parent: automationAccount
  name: '15min'
  properties: {
    description: 'Runs every 15 minutes'
    frequency: 'Minute'
    interval: any(15)
    startTime: scheduleStartDate
  }
}

resource runbookJobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = {
  parent: automationAccount
  name: guid('${runbookName}-15min-${subscriptionId}')
  properties: {
    parameters: {
      SubscriptionId: subscriptionId
    }
    runbook: {
      name: runbookName
    }
    schedule: {
      name: '15min'
    }
  }
}
