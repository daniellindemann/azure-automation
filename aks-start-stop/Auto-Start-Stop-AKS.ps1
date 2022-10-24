<#
    .DESCRIPTION
        An example runbook which gets all the ARM resources using the Managed Identity

    .NOTES
        AUTHOR: Azure Automation Team
        LASTEDIT: Oct 26, 2021
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

"Add variables"
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

		$resourceGroup = $aksCluster.ResourceGroupName  # when executing via automation account, the resource group will not be fetched, so get it via regex from the id
        if(!$resourceGroup) {
            $regex = [regex] "\/resourcegroups\/([A-Za-z0-9\-_]{1,})\/"
            $resourceGroup = $regex.Match($aksCluster.Id).Groups[1].Value
        }

        if($null -ne $businessHoursStart -and $null -ne $businessHoursEnd) {
            $startDate = [DateTime]::Parse($isoDateStringTemplate + $businessHoursStart)
            $stopDate = [DateTime]::Parse($isoDateStringTemplate + $businessHoursEnd)

            # check if aks should be started
            if($timeUtc -ge $startDate -and
                $timeUtc -lt $stopDate -and
                $businessHoursDays.Contains($currentDay) -and
                $powerState -ne 'Running' -and
                $provisioningState -eq 'Succeeded') {
                    Start-AzAksCluster -Name $aksCluster.Name -ResourceGroupName $resourceGroup
                    "Started AKS $($aksCluster.Name) in resource group $resourceGroup"
            }
            
            # check if aks should be stopped
            if(($timeUtc -ge $stopDate -or
                $timeUtc -lt $startDate) -and
                $businessHoursDays.Contains($currentDay) -and
                $powerState -ne 'Stopped' -and
                $provisioningState -eq 'Succeeded') {
                    Stop-AzAksCluster -Name $aksCluster.Name -ResourceGroupName $resourceGroup
                    "Stopped AKS $($aksCluster.Name) in resource group $resourceGroup"
            }
        }
    }
}

if(!$ClusterName) {
	"Run for all clusters in subscription"
    # Loop through aks clusters in the subsription
    $aksClusters = Get-AzAksCluster
    StartStopCluster $aksClusters
}
else {
	"Run for specific cluster"
    # stop/stop specific cluster
    $specificCluster = Get-AzAksCluster -Name $ClusterName -ResourceGroupName $ResourceGroupName
    StartStopCluster @($specificCluster)
}
