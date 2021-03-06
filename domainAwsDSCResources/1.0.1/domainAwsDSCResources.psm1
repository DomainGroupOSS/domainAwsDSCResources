
#Basic Enums used by DSC
enum Ensure
{
    Present
    Absent
}

<#
Module Mixed by BarTender
	A Framework for making PowerShell Modules
	Version: 6.1.22
	Author: Adrian.Andersson
	Copyright: 2019 Domain Group

Module Details:
	Module: domainAwsDSCResources
	Description: DSC Resources for AWS EC2 Instances
	Revision: 1.0.0.2
	Author: Adrian.Andersson
	Company: Domain Group

Check Manifest for more details
#>

[DscResource()]
class dmAwsTagInstance{
    [DscProperty(Mandatory)]
    [Ensure] $Ensure
    [DscProperty(Key)]
    [string] $name
    [DscProperty()]
    [hashtable] $instanceTags
    [DscProperty()]
    [string]$instanceId
    [DscProperty(NotConfigurable)]
    [Nullable[datetime]] $CreationTime
    hidden [hashtable] $currentTags = @{}
    [void] Set()
    {
        write-verbose 'Set kicked off'
        
        
        if($this.currentTags.count -eq 0)
        {
            write-verbose 'I have no tags, getting them'
            $this.GetCurrentTags()
        }
        
        if($this.instanceTags.count -gt 0)
        {
            write-verbose 'Adding new tags'
            Foreach($tag in $this.instanceTags.keys)
            {
                write-verbose "Adding tag for $tag"
                
                $tagValue = $this.instanceTags."$tag".tostring().trim()
                write-verbose "Value: $tagValue"
                New-EC2Tag -Tag (New-Object -TypeName Amazon.EC2.Model.Tag -ArgumentList @($tag, $tagValue )) -Resource $this.instanceId
            }
        }else{
            write-verbose 'No new tags to add'
        }
        
        
    }
    [bool] Test()
    {
        write-verbose 'test init'
        if($this.currentTags.count -eq 0)
        {
            write-verbose 'I have no tags, getting them'
            $this.GetCurrentTags()
        }
        write-verbose 'Comparing tags'
        try{
            $tagsCompare = $this.instanceTags|where-object {$this.CurrentTags.Values -notcontains $_}
            if($($tagsCompare|measure-object).count -ge 1)
            {
                return $false
            }else{
                return $true
            }
            
        }catch{
            write-error 'Stuffed up the tag compare'
            return $false
        }
        
    }
    [dmAwsTagInstance] Get()
    {
        
        return $this
    }
    [void] GetCurrentTags()
    {
        write-verbose 'Getting current tags'
        write-verbose 'Importing module'
        
        write-verbose 'Reading the current tags in'
        try{
       
            $tags = $(get-ec2instance $this.InstanceId).Instances.Tags
            foreach($tag in $tags)
            {
                $this.currentTags."$($tag.key)" = "$($tag.value)"
            }
            write-verbose 'Got the current tags'
        }catch{
            write-error 'Unable to read the current tags for some reason'
        }
    }
}

[DscResource()]
class dmAwsTimeSync{
    [DscProperty(Mandatory)]
    [Ensure] $Ensure
    [DscProperty(Key)]
    [string] $timeZoneName
    [DscProperty(NotConfigurable)]
    [Nullable[datetime]] $CreationTime
    #The AWS Hard-Coded Time Server endpoint IP
    hidden [string] $awsTimeSyncServer = '169.254.169.123'
    #How often should we sync the time, in seconds, 3600 = 1 hr
    hidden [int] $timePollSeconds = 3600
    #NtpClientPath
    hidden [string] $NtpClientPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient'
    #Used by getPollInterval
    hidden [string] $currentPollInterval
    #Used by getTimeServerDetails
    hidden [string] $currentTimeSource
    hidden [datetime] $lastTimeSync
    #Used by getTimeZone
    hidden [string] $currentTimeZone
    [void] Set()
    {
        if ($this.ensure -eq [Ensure]::Present)
        {
            if($($this.test()) -eq $false)
            {
                #We need to set the time stuff up, so run the subfunctions
                Write-Verbose 'Setting the time up'
                Stop-Service w32time -Force
                $this.setPollInterval()
                $this.setAwsTimeServer()
                $this.setTimeZone()
                Start-Service W32Time
                write-verbose 'Sleeping for 10 seconds, then trying to force a date update'
                Start-Sleep -Seconds 10
                #Seems to be needed for the computer to realise its changed
                get-timezone | out-null  
                get-date |Out-Null
            }
        } else {
            #Well we just dont care I guess
        }
    }
    [bool] Test()
    {
        $this.getPollInterval()
        $this.getTimeServerDetails()
        $this.getTimeZone()
        if($this.currentTimeZone -eq $this.timezonename -and $this.currentPollInterval -eq $this.currentPollInterval -and $this.currentTimeSource -eq $this.awsTimeSyncServer)
        {
            return $true
        }else{
            return $false
        }
    }
    [dmAwsTimeSync] Get()
    {
        $this.getPollInterval()
        $this.getTimeServerDetails()
        $this.getTimeZone()
        return $this
    }
    [void] setAwsTimeServer()
    {
        Write-Verbose 'Configuring to use AWS time sync'
        try{
            Start-Process -FilePath 'w32tm' -ArgumentList "/config /syncfromflags:manual /manualpeerlist:`"$($this.awsTimeSyncServer)`""
            Start-Process -FilePath 'w32tm' -ArgumentList '/config /reliable:yes'
            Write-Verbose 'AWS TimeServer Configured'
        }catch{
            Write-Verbose 'Configuring AWS TimeSync failed'
            Write-Error 'Config of AWS TimeSync failed'
            
        }
    }
    [void] setPollInterval()
    {
        Write-Verbose 'Setting Time Poll Interval in Registry'
        
        $this.getPollInterval()
        Write-Verbose "Existing property value: $($this.currentPollInterval)"
        try{
            Set-ItemProperty -Path $this.NtpClientPath -Name SpecialPollInterval -Value $this.timePollSeconds
            Write-Verbose 'Time Poll Set'
        }catch{
            Write-Verbose 'Time Poll not set'
            Write-Error 'Config of Time Poll failed'
        }
    }
    [void] getPollInterval()
    {
        $this.currentPollInterval = $(get-ItemProperty -Path $this.NtpClientPath -Name SpecialPollInterval)
    }
    [void] getTimeServerDetails()
    {
        $status = w32tm /query /status
        $this.currentTimeSource = $($($status|Where-Object{$_ -like 'Source:*'}) -replace 'Source: ','').trim()
        $this.lastTimeSync = get-date "$($($status|Where-Object{$_ -like 'Last Successful Sync Time:*'}) -replace 'Last Successful Sync Time: ','')"
    }
    [void] getTimeZone()
    {
        $this.currentTimeZone = $(get-timezone).Id
    }
    [void] setTimeZone()
    {
        write-verbose 'setting TimeZone'
        try{
            set-timezone -Name $this.timezoneName
            write-verbose 'Timezone Set'
        }catch{
            Write-Verbose 'Setting Timezone Failed'
            write-error 'Error setting timezone'
        }
    }
}

