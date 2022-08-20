
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

// ============================================================================================================

@allowed([
    0
    1
    2
    3
    4
])
@description('Severity of alert {0,1,2,3,4}')
param severity int = 3

@allowed([
    'PT1M'
    'PT5M'
    'PT15M'
    'PT30M'
    'PT1H'
])
@description('How often the metric alert is evaluated represented in ISO 8601 duration format')
param evaluationFrequency string = 'PT1H'

@allowed([
    'PT1M'
    'PT5M'
    'PT15M'
    'PT30M'
    'PT1H'
    'PT6H'
    'PT12H'
    'PT24H'
])
@description('Period of time used to monitor alert activity based on the threshold. Must be between one minute and one day. ISO 8601 duration format.')
param windowSize string = 'PT24H'

@allowed([
    'PT1M'
    'PT5M'
    'PT15M'
    'PT30M'
    'PT1H'
    'PT6H'
    'PT12H'
    'PT24H'
])
@description('Mute actions for the chosen period of time (in ISO 8601 duration format) after the alert is fired.')
param muteActionsDuration string = 'PT24H'

@allowed([
    'Average'
    'Minimum'
    'Maximum'
    'Total'
    'Count'
])
@description('How the data that is collected should be combined over time.')
param timeAggregation string = 'Average'

@description('Specifies whether the alert will automatically resolve')
param autoMitigate bool = true

@description('Specifies whether to check linked storage and fail creation if the storage was not found')
param checkWorkspaceAlertsStorageConfigured bool = false

@description('The ID of the action group that is triggered when the alert is activated or deactivated')
param actionGroupId string

resource queryrule 'Microsoft.Insights/scheduledQueryRules@2021-08-01' = {
    name: 'ExpiredAppRegistrationsRule'
    location: location
    properties: {
        description: 'Log alert for expired app registration secrets and certificates'
        severity: severity
        enabled: true
        // scopes:
        evaluationFrequency: evaluationFrequency
        windowSize: windowSize
        criteria: {
            allOf: [
                {
                    query: ''
                    metricMeasureColumn: ''
                    resourceIdColumn: ''
                    dimensions: []
                    operator: 'Equals'
                    threshold: 0
                    timeAggregation: timeAggregation
                    failingPeriods: {
                        numberOfEvaluationPeriods: 4
                        minFailingPeriodsToAlert: 3
                    }
                }
            ]
        }
        muteActionsDuration: muteActionsDuration
        autoMitigate: autoMitigate
        checkWorkspaceAlertsStorageConfigured: checkWorkspaceAlertsStorageConfigured
        actions: {
            actionGroups: array(actionGroupId)
            customProperties: {
                key1: 'value1'
            }
        }
    }
}
