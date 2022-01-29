
@description('Name of the automation account')
param automationAccountName string

@description('Log Analytics Workspace to write expiring secret information to')
param logAnalyticsWorkspaceId string

@description('Log Analytics Workspace key')
@secure()
param logAnalyticsWorkspaceKey string

@description('Runbook Uri')
param runbookUri string = 'https://raw.githubusercontent.com/daniellindemann/azure-automation/development/WriteExpiringSecretsAndCertificatesToLogAnalytics/WriteExpiringSecretsAndCertificatesToLogAnalytics.ps1'

@description('Schedule start time (at deployment time 10 minutes will be added to the schedule)')
param scheduleStartTime string = utcNow('o')

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
        startTime: dateTimeAdd(scheduleStartTime, 'PT10M', 'o')
    }
}

resource jobschedule 'Microsoft.Automation/automationAccounts/jobSchedules@2019-06-01' = {
    parent: automationAccount
    name: guid(runbookName, schedule.name)
    properties: {
        runbook: {
            name: runbook.name
        }
        schedule: {
            name: schedule.name
        }
        parameters: {
            'LogAnalyticsWorkspaceId': logAnalyticsWorkspaceId
            'LogAnalyticsWorkspaceKey': logAnalyticsWorkspaceKey
        }
    }
}
