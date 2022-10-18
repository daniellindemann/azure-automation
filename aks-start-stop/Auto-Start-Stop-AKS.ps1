<#
    .DESCRIPTION
        Runbook to start and stop AKS clusters using the Managed Identity.
        The runbook checks for the existance of specific tags to control start and stop actions

    .NOTES
        AUTHOR: Daniel Lindemann
        LASTEDIT: Oct 18, 2022
#>

<#
    For local dev exec like
    .\Auto-Start-Stop-AKS.ps1 -SubscriptionId (Get-AzContext).Subscription.Id -LocalTest
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string]
    $ClusterName,

    [Parameter(Mandatory = $false)]
    [string]
    $ResourceGroupName,

    # Search for these tags configured within the cluster
    $TagNameBusinessHoursDays = 'Business Hours Days',
    $TagNameBusinessHoursStart = 'Business Hours Start',
    $TagNameBusinessHoursEnd = 'Business Hours End',

    # Default Values
    $DefaultTagBusinessHoursDays = 'Mon,Tue,Wed,Thu,Fri',

    # Params for local dev
    [switch]
    $LocalTest
)

if(!$LocalTest) {
    "Please enable appropriate RBAC permissions to the system identity of this automation account. Otherwise, the runbook may fail..."

    try
    {
        "Logging in to Azure..."
        Connect-AzAccount -Identity

        "Select Azure Subscription"
        Select-AzSubscription -SubscriptionId $SubscriptionId
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$timeUtc = (Get-Date).ToUniversalTime()
$currentDay = $timeUtc.ToString('ddd')
$isoDateStringTemplate = $timeUtc.ToString('yyyy-MM-ddT')

function StartStopCluster {
    param (
        [Parameter(Mandatory = $true)]
        $clusters
    )
    
    foreach ($aksCluster in $clusters) {
        # get data
        $businessHoursDays = $aksCluster.Tags[$TagNameBusinessHoursDays]
        $businessHoursStart = $aksCluster.Tags[$TagNameBusinessHoursStart]
        $businessHoursEnd = $aksCluster.Tags[$TagNameBusinessHoursEnd]

        $powerState = $aksCluster.PowerState.Code   # can be Stopped and Started
        $provisioningState = $aksCluster.ProvisioningState  # can be Succeeded

        if($null -ne $businessHoursStart -and $null -ne $businessHoursEnd) {
            $startDate = [DateTime]::Parse($isoDateStringTemplate + $businessHoursStart)
            $stopDate = [DateTime]::Parse($isoDateStringTemplate + $businessHoursEnd)

            # check if aks should be started
            if($timeUtc -ge $startDate -and
                $timeUtc -lt $stopDate -and
                $businessHoursDays.Contains($currentDay) -and
                $powerState -ne 'Running' -and
                $provisioningState -eq 'Succeeded') {
                    Start-AzAksCluster -Name $aksCluster.Name -ResourceGroupName $aksCluster.ResourceGroupName
                    "Started AKS $($aksCluster.Name) in resource group $($aksCluster.ResourceGroupName)"
                }
            
            # check if aks should be stopped
            if(($timeUtc -ge $stopDate -or
                $timeUtc -lt $startDate) -and
                $businessHoursDays.Contains($currentDay) -and
                $powerState -ne 'Stopped' -and
                $provisioningState -eq 'Succeeded') {
                    Stop-AzAksCluster -Name $aksCluster.Name -ResourceGroupName $aksCluster.ResourceGroupName
                    "Stopped AKS $($aksCluster.Name) in resource group $($aksCluster.ResourceGroupName)"
                }
        }
    }
}

if(!$ClusterName) {
    # Loop through aks clusters in the subsription
    $aksClusters = Get-AzAksCluster
    StartStopCluster $aksClusters
}
else {
    # stop/stop specific cluster
    $specificCluster = Get-AzAksCluster -Name $ClusterName -ResourceGroupName $ResourceGroupName
    StartStopCluster @($specificCluster)
}
