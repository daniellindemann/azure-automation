@description('Automation Account name')
param automationAccountName string

@description('''
Schedule start date (must be in the future)
Use ISO8601 date string, e.g. '2022-10-19T10:01:00+02:00'
''')
param scheduleStartDate string = dateTimeAdd(utcNow(), 'PT1H')

@description('Location of automation account')
param location string = resourceGroup().location

@description('Required Guid for the job schedule creation')
param jobScheduleGuid string = newGuid()

var scriptUri = 'https://raw.githubusercontent.com/daniellindemann/azure-automation/dev/aks-start-stop/aks-start-stop/Auto-Start-Stop-AKS.ps1'

resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' existing = {
  name: automationAccountName
}

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2022-08-08' = {
  name: '${automationAccount.name}/AutoStartStopAks'
  location: location
  properties: {
    runbookType: 'PowerShell7'
    publishContentLink: {
      uri: scriptUri
      version: '1.0.0.0'
    }
  }
}

resource runbookSchedule 'Microsoft.Automation/automationAccounts/schedules@2022-08-08' = {
  name: '${automationAccount.name}/15min'
  properties: {
    description: 'Runs every 15 minutes'
    frequency: 'Minute'
    interval: any(15)
    startTime: scheduleStartDate
  }
}

resource runbookJobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = {
#disable-next-line use-stable-resource-identifiers
  name: '${automationAccount.name}/${jobScheduleGuid}'
  properties: {
    parameters: {
      SubscriptionId: subscription().subscriptionId
    }
    runbook: {
      name: substring(runbook.name, lastIndexOf(runbook.name, '/') + 1)
    }
    schedule: {
      name: '15min'
    }
  }
}
