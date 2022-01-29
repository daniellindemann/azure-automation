
@description('Name of the automation account')
param automationAccountName string

@description('Runbook Uri')
param runbookUri string = 'https://raw.githubusercontent.com/daniellindemann/azure-automation/development/WriteExpiringSecretsAndCertificatesToLogAnalytics/WriteExpiringSecretsAndCertificatesToLogAnalytics.ps1'

@description('Schedule start time')
param scheduleStartTime string = dateTimeAdd(utcNow(), 'PT1H', 'o')

// @description('Create storage account, if not existing')
// param createStorageAccount bool = false

var location = resourceGroup().location
var runbookName = replace(substring(runbookUri, lastIndexOf(runbookUri, '/') + 1), '.ps1', '')

resource automationAccount 'Microsoft.Automation/automationAccounts@2019-06-01' existing = {
    name: automationAccountName
}

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
    parent: automationAccount
    name: runbookName
    location: location
    properties: {
        runbookType: 'PowerShell'
        logProgress: true
        logVerbose: false
        publishContentLink: {
            uri: runbookUri
        }
    }
}

resource schedule 'Microsoft.Automation/automationAccounts/schedules@2019-06-01' = {
    parent: automationAccount
    name: 'Daily for ${runbookName}'
    properties: {
        frequency: 'Day'
        description: 'Runs ${runbookName} daily'
        interval: 1
        startTime: scheduleStartTime
    }
}

resource jobschedule 'Microsoft.Automation/automationAccounts/jobSchedules@2019-06-01' = {
    parent: automationAccount
    name: guid(runbookName, schedule.name)
    properties: {
        runbook: runbook
        schedule: schedule
    }
}

// resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = [for runbook in runbooks: {
//     parent: automationAccount
//     name: runbook.runbookName
//     location: location
//     properties: {
//       runbookType: runbook.runbookType
//       logProgress: runbook.logProgress
//       logVerbose: runbook.logVerbose
//       publishContentLink: {
//         uri: runbook.runbookUri
//       }
//     }
//   }]
