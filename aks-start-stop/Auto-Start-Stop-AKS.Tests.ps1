BeforeAll {
    . "$PSScriptRoot\Auto-Start-Stop-AKS.ps1" -LocalTest -SubscriptionId "00000000-0000-0000-0000-000000000000"
}

Describe 'ShouldBeRunning' {
    It 'returns true if time is in time range' {
        $timeUtc = [DateTime]::Parse('2024-04-06T12:00:00Z')
        $isoDateStringPrefix = $timeUtc.ToString('yyyy-MM-ddT')
        $day = 'Mon'

        $startHour = '06:00'
        $stopHour = '18:00'

        $start = [DateTime]::Parse($isoDateStringPrefix + $startHour)
        $end = [DateTime]::Parse($isoDateStringPrefix + $stopHour)
        $businessDays = 'Mon,Tue,Wed,Thu,Fri'

        $result = ShouldBeRunning $timeUtc $day $start $end $businessDays

        $result | Should -Be $true
    }

    It 'return false if time is outside time range' {
        $timeUtc = [DateTime]::Parse('2024-04-06T04:00:00Z')
        $isoDateStringPrefix = $timeUtc.ToString('yyyy-MM-ddT')
        $day = 'Mon'

        $startHour = '06:00'
        $stopHour = '18:00'

        $start = [DateTime]::Parse($isoDateStringPrefix + $startHour)
        $end = [DateTime]::Parse($isoDateStringPrefix + $stopHour)
        $businessDays = 'Mon,Tue,Wed,Thu,Fri'

        $result = ShouldBeRunning $timeUtc $day $start $end $businessDays

        $result | Should -Be $false
    }

    It 'return true if day is in business days' {
        $timeUtc = [DateTime]::Parse('2024-04-06T04:00:00Z')
        $isoDateStringPrefix = $timeUtc.ToString('yyyy-MM-ddT')
        $day = 'Mon'

        $startHour = '06:00'
        $stopHour = '18:00'

        $start = [DateTime]::Parse($isoDateStringPrefix + $startHour)
        $end = [DateTime]::Parse($isoDateStringPrefix + $stopHour)
        $businessDays = 'Mon,True'

        $result = ShouldBeRunning $timeUtc $day $start $end $businessDays

        $result | Should -Be $false
    }

    It 'return false if day is outside business days' {
        $timeUtc = [DateTime]::Parse('2024-04-06T04:00:00Z')
        $isoDateStringPrefix = $timeUtc.ToString('yyyy-MM-ddT')
        $day = 'Sat'

        $startHour = '06:00'
        $stopHour = '18:00'

        $start = [DateTime]::Parse($isoDateStringPrefix + $startHour)
        $end = [DateTime]::Parse($isoDateStringPrefix + $stopHour)
        $businessDays = 'Mon,Tue,Wed,Thu,Fri'

        $result = ShouldBeRunning $timeUtc $day $start $end $businessDays

        $result | Should -Be $false
    }
}

Describe 'ShouldBeStopped' {
    It 'returns true if time is outside time range' {
        $timeUtc = [DateTime]::Parse('2024-04-06T02:00:00Z')
        $isoDateStringPrefix = $timeUtc.ToString('yyyy-MM-ddT')
        $day = 'Mon'

        $startHour = '06:00'
        $stopHour = '18:00'

        $start = [DateTime]::Parse($isoDateStringPrefix + $startHour)
        $end = [DateTime]::Parse($isoDateStringPrefix + $stopHour)
        $businessDays = 'Mon,Tue,Wed,Thu,Fri'

        $result = ShouldBeStopped $timeUtc $day $start $end $businessDays

        $result | Should -Be $true
    }

    It 'returns false if time is inside time range' {
        $timeUtc = [DateTime]::Parse('2024-04-06T08:00:00Z')
        $isoDateStringPrefix = $timeUtc.ToString('yyyy-MM-ddT')
        $day = 'Mon'

        $startHour = '06:00'
        $stopHour = '18:00'

        $start = [DateTime]::Parse($isoDateStringPrefix + $startHour)
        $end = [DateTime]::Parse($isoDateStringPrefix + $stopHour)
        $businessDays = 'Mon,Tue,Wed,Thu,Fri'

        $result = ShouldBeStopped $timeUtc $day $start $end $businessDays

        $result | Should -Be $false
    }

    It 'return true if day is outside business days' {
        $timeUtc = [DateTime]::Parse('2024-04-06T12:00:00Z')
        $isoDateStringPrefix = $timeUtc.ToString('yyyy-MM-ddT')
        $day = 'Sat'

        $startHour = '06:00'
        $stopHour = '18:00'

        $start = [DateTime]::Parse($isoDateStringPrefix + $startHour)
        $end = [DateTime]::Parse($isoDateStringPrefix + $stopHour)
        $businessDays = 'Mon,True'

        $result = ShouldBeStopped $timeUtc $day $start $end $businessDays

        $result | Should -Be $true
    }

    It 'return false if day is inside business days' {
        $timeUtc = [DateTime]::Parse('2024-04-06T12:00:00Z')
        $isoDateStringPrefix = $timeUtc.ToString('yyyy-MM-ddT')
        $day = 'Mon'

        $startHour = '06:00'
        $stopHour = '18:00'

        $start = [DateTime]::Parse($isoDateStringPrefix + $startHour)
        $end = [DateTime]::Parse($isoDateStringPrefix + $stopHour)
        $businessDays = 'Mon,Tue'

        $result = ShouldBeStopped $timeUtc $day $start $end $businessDays

        $result | Should -Be $false
    }
}
