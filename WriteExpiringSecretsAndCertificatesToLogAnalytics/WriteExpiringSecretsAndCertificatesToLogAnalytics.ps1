<#
    .DESCRIPTION
        TODO

    .NOTES
        TODO
        AUTHOR: Azure Automation Team
        LASTEDIT: Oct 26, 2021
#>

<#
    Script created with the help of the create work of Cj-Scott; see https://github.com/Cj-Scott/Get-AppRegistrationExpiration
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $LogAnalyticsWorkspaceId,

    [Parameter(Mandatory = $true)]
    [string]
    $LogAnalyticsWorkspaceKey
)

$lawId = [System.Guid]::Empty
if([System.Guid]::TryParse($LogAnalyticsWorkspaceId, [ref]$lawId) -eq $false) {
    $castException = New-Object -TypeName System.InvalidCastException -ArgumentList "LogAnalyticsWorkspaceId is not a valid Guid"
    Write-Error $castException.Message
    throw $castException
}

if($null -ne $env:AUTOMATION_ASSET_ACCOUNTID) {
    Write-Output "Please enable appropriate RBAC permissions to the system identity of this automation account. Otherwise, the runbook may fail..."

    Write-Output "Logging in to Azure..."
    Connect-AzAccount -Identity
}

# defaults
$timeStampField = "TimeStamp"
$logType = "AppRegistrationExpiration"

Write-Output "Retrieving apps and secret information ..."
$azResourcesModuleMajorVersion = (Get-Module -ListAvailable -Name Az.Resources).Version.Major
$applications = Get-AzADApplication
$appWithCredentials = @()
$appWithCredentials += $applications | ForEach-Object {
    $application = $_
    Write-Verbose ('Fetching information for application {0}' -f $application.DisplayName)

    $appCredentials = $application | Get-AzADAppCredential

    # the response objects for applications and app credentials changed from version 4 to version 5 of the Az.Resources module (which includes the cmdlets Get-AzADApplication and Get-AzADAppCredential)
    # in the time of writing the version 5.2.0 of the Az.Resources module was used
    # Azure Automation used version 4.4.0 during this time
    if($azResourcesModuleMajorVersion -ge 5) {
        $appCredentials | Select-Object `
            -Property @{ Name='DisplayName'; Expression={$application.DisplayName} }, `
            @{ Name='ObjectId'; Expression={$application.Id} }, `
            @{ Name='AppId'; Expression={$application.AppId} }, `
            @{ Name='KeyId'; Expression={$_.KeyId} }, `
            @{ Name='Type'; Expression={$_.Type} }, `
            @{ Name='StartDate'; Expression={$_.StartDateTime} }, `
            @{ Name='EndDate'; Expression={$_.EndDateTime} }
    }
    else {
        $appCredentials | Select-Object `
            -Property @{ Name='DisplayName'; Expression={$application.DisplayName} }, `
            @{ Name='ObjectId'; Expression={$application.ObjectId} }, `
            @{ Name='AppId'; Expression={$application.ApplicationId} }, `
            @{ Name='KeyId'; Expression={$_.KeyId} }, `
            @{ Name='Type'; Expression={$_.Type} }, `
            @{ Name='StartDate'; Expression={$_.StartDate -as [datetime]} }, `
            @{ Name='EndDate'; Expression={$_.EndDate -as [datetime]} }
    }
}

$today = (Get-Date).ToUniversalTime()
$timestamp = $today.ToString('o')
$appWithCredentials | ForEach-Object {
    $days = ($_.EndDate - $Today).Days

    $_ | Add-Member -MemberType NoteProperty -Name $timeStampField -Value $timestamp -Force
    $_ | Add-Member -MemberType NoteProperty -Name 'DaysToExpiration' -Value $days -Force

    if($_.EndDate -lt $today) {
        $_ | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'Expired' -Force
    }  else {
        $_ | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'Valid' -Force
    }
}

Write-Output "Push data to Log Analytics Workspace ..."
$appWithCredentialsJson = $appWithCredentials | ConvertTo-Json

# send to log analytics workspace
$body = [System.Text.Encoding]::UTF8.GetBytes($appWithCredentialsJson)
$method = "POST"
$contentType = "application/json"
$resource = "/api/logs"
$rfc1123date = [DateTime]::UtcNow.ToString("r")
$contentLength = $body.Length

# create the encoded hash to be used in the authorization signature
$xHeaders = "x-ms-date:" + $rfc1123date
$stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource
$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
$keyBytes = [Convert]::FromBase64String($LogAnalyticsWorkspaceKey)
$sha256 = New-Object System.Security.Cryptography.HMACSHA256
$sha256.Key = $keyBytes
$calculatedHash = $sha256.ComputeHash($bytesToHash)
$encodedHash = [Convert]::ToBase64String($calculatedHash)
$authorization = 'SharedKey {0}:{1}' -f $lawId,$encodedHash

# build url
$url = "https://" + $lawId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

$headers = @{
    "Authorization" = $authorization;
    "Log-Type" = $logType;
    "x-ms-date" = $rfc1123date;
    "time-generated-field" = $timeStampField;
}

# send data to log analytics workspace
$response = Invoke-WebRequest `
    -Uri $url `
    -Method $method `
    -ContentType $contentType `
    -Headers $headers `
    -Body $body `
    -UseBasicParsing `
    -ErrorAction Stop

Write-Output $response

Write-Output "Done"
