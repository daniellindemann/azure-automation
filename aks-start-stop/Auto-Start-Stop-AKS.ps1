<#
    .DESCRIPTION
        This runbook starts and stops Azure Kubernetes Service clusters at a specific time.

    .NOTES
        AUTHOR: Daniel Lindemann
        LASTEDIT: Dec 22, 2022
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
    [Parameter(Mandatory = $false)]
    [string]
    $TagNameBusinessHoursDays = 'auto-aks-days',

    [Parameter(Mandatory = $false)]
    [string]
    $TagNameBusinessHoursStart = 'auto-aks-start-at-utc',

    [Parameter(Mandatory = $false)]
    [string]
    $TagNameBusinessHoursEnd = 'auto-aks-stop-at-utc',

    # Default Values
    [Parameter(Mandatory = $false)]
    [string]
    $DefaultTagBusinessHoursDays = 'Mon,Tue,Wed,Thu,Fri',

    # Params for local test via pester
    [switch]
    $LocalTest
)

if(!$LocalTest) {
    Write-Output "Please enable appropriate RBAC permissions to the system identity of this automation account. Otherwise, the runbook may fail..."

    try
    {
        Write-Output "Logging in to Azure..."
        Connect-AzAccount -Identity

        Write-Output "Set subscription" -Verbose
        Select-AzSubscription -SubscriptionId $SubscriptionId
        Write-Output "Subscription is $SubscriptionId" -Verbose
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$timeUtc = (Get-Date).ToUniversalTime()
Write-Output "Current UTC time: $timeUtc" -Verbose
$currentDay = $timeUtc.ToString('ddd')
Write-Output "Current day: $currentDay" -Verbose
$isoDateStringTemplate = $timeUtc.ToString('yyyy-MM-ddT')

function ShouldBeRunning {
    param (
        [Parameter(Mandatory = $true)]
        $currentDateTimeUtc,
        [Parameter(Mandatory = $true)]
        $currentDay,
        [Parameter(Mandatory = $true)]
        $startDateUtc,
        [Parameter(Mandatory = $true)]
        $stopDateUtc,
        [Parameter(Mandatory = $true)]
        $businessDays
    )

    $shouldBeRunningResult = $timeUtc -ge $startDateUtc -and
                $timeUtc -lt $stopDateUtc -and
                $businessDays.Contains($currentDay)
    
    return $shouldBeRunningResult
}

function ShouldBeStopped {
    param (
        [Parameter(Mandatory = $true)]
        $currentDateTimeUtc,
        [Parameter(Mandatory = $true)]
        $currentDay,
        [Parameter(Mandatory = $true)]
        $startDateUtc,
        [Parameter(Mandatory = $true)]
        $stopDateUtc,
        [Parameter(Mandatory = $true)]
        $businessDays
    )

    $shouldBeStoppedResult = $currentDateTimeUtc -ge $stopDateUtc -or
        $currentDateTimeUtc  -lt $startDateUtc -or
        $businessDays.Split(',') -notcontains $currentDay

    return $shouldBeStoppedResult
}

function StartStopCluster {
    param (
        [Parameter(Mandatory = $true)]
        $clusters
    )

    foreach ($aksCluster in $clusters) {

        Write-Output "Checking $($aksCluster.Name)"

        # get data
        $businessHoursDays = $aksCluster.Tags[$TagNameBusinessHoursDays]
        if(!$businessHoursDays) {
            $businessHoursDays = $DefaultTagBusinessHoursDays
        }
        $businessHoursStart = $aksCluster.Tags[$TagNameBusinessHoursStart]
        $businessHoursEnd = $aksCluster.Tags[$TagNameBusinessHoursEnd]
        Write-Output "`tBusiness hours days: $businessHoursDays" -Verbose
        Write-Output "`tBusiness hours start: $businessHoursStart" -Verbose
        Write-Output "`tBusiness hours end: $businessHoursEnd" -Verbose

        $powerState = $aksCluster.PowerState.Code   # can be Stopped and Started
        Write-Output "`tPower state: $powerState" -Verbose
        $provisioningState = $aksCluster.ProvisioningState  # can be Succeeded
        Write-Output "`tProvisioning state: $provisioningState" -Verbose

		$resourceGroup = $aksCluster.ResourceGroupName  # when executing via automation account, the resource group will not be fetched, so get it via regex from the id
        Write-Output "`tResource group via cluster property: $resourceGroup" -Verbose
        if(!$resourceGroup) {
            $regex = [regex] "\/resourcegroups\/([A-Za-z0-9\-_]{1,})\/"
            $resourceGroup = $regex.Match($aksCluster.Id).Groups[1].Value
            Write-Output "`tResource group name updated via resource id regex extraction: $resourceGroup" -Verbose
        }

        if($null -ne $businessHoursStart -and $null -ne $businessHoursEnd) {

            Write-Output "`t$($aksCluster.Name) has tags $TagNameBusinessHoursStart and $TagNameBusinessHoursEnd"

            $startDate = [DateTime]::Parse($isoDateStringTemplate + $businessHoursStart)
            Write-Output "`tStart date: $startDate" -Verbose
            $stopDate = [DateTime]::Parse($isoDateStringTemplate + $businessHoursEnd)
            Write-Output "`tStop date: $stopDate" -Verbose

            $shouldBeRunning = ShouldBeRunning $timeUtc $currentDay $startDate $stopDate $businessHoursDays
            Write-Output "`tShould be running: $shouldBeRunning" -Verbose
            $shouldBeStopped = ShouldBeStopped $timeUtc $currentDay $startDate $stopDate $businessHoursDays
            Write-Output "`tShould be stopped: $shouldBeStopped" -Verbose

            # check if aks should be started
            if($shouldBeRunning -and
                $powerState -ne 'Running' -and
                $provisioningState -eq 'Succeeded') {
                    Write-Output "`tStarting AKS $($aksCluster.Name) in resource group $resourceGroup" -Verbose
                    Start-AzAksCluster -Name $aksCluster.Name -ResourceGroupName $resourceGroup
                    Write-Output "`tStarted AKS $($aksCluster.Name) in resource group $resourceGroup"
            }
            # check if aks should be stopped
            elseif($shouldBeStopped -and
                $powerState -ne 'Stopped' -and
                $provisioningState -eq 'Succeeded') {
                    Write-Output "`tStopping AKS $($aksCluster.Name) in resource group $resourceGroup" -Verbose
                    Stop-AzAksCluster -Name $aksCluster.Name -ResourceGroupName $resourceGroup
                    Write-Output "`tStopped AKS $($aksCluster.Name) in resource group $resourceGroup"
            }
            else  {
                Write-Output "`tCluster $($aksCluster.Name) is in correct state. No action required."
            }
        }
    }
}

if(!$LocalTest) {
    if(!$ClusterName) {
        Write-Output "Run for all clusters in subscription"
        # Loop through aks clusters in the subsription
        $aksClusters = Get-AzAksCluster
        StartStopCluster $aksClusters
    }
    else {
        Write-Output "Run for specific cluster"
        # stop/stop specific cluster
        $specificCluster = Get-AzAksCluster -Name $ClusterName -ResourceGroupName $ResourceGroupName
        StartStopCluster @($specificCluster)
    }
}
