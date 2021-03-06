# DOMAINAWSDSCRESOURCES


> DSC Resources for AWS EC2 Instances

[releasebadge]: https://img.shields.io/static/v1.svg?label=version&message=1.0.1&color=blue
[datebadge]: https://img.shields.io/static/v1.svg?label=Date&message=2019-03-18&color=yellow
[psbadge]: https://img.shields.io/static/v1.svg?label=PowerShell&message=5.0.0&color=5391FE&logo=powershell
[btbadge]: https://img.shields.io/static/v1.svg?label=bartender&message=6.1.22&color=0B2047


| Language | Release Version | Release Date | Bartender Version |
|:-------------------:|:-------------------:|:-------------------:|:-------------------:|
|![psbadge]|![releasebadge]|![datebadge]|![btbadge]|


Authors: Adrian.Andersson

Company: Domain Group

Latest Release Notes: [here](./documentation/1.0.1/release.md)

***

<!--Bartender Dynamic Header -- Code Below Here -->



***
##  Getting Started

### Installation
How to install:
```powershell
install-module domainAwsDSCResources

```

---

### Example

> Local DSC create/Execute (Not push/pull)

> Assumes directory and execution location is already done

> Assumes your EC2 instances have sufficient permissions to self-tag


```powershell


# Set the DSC Configuration 
configuration myEc2Configuration
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$timeZoneName,
        [Parameter(Mandatory=$true)]
        [string]$instanceId,
        [Parameter(Mandatory=$true)]
        [hashtable]$instanceTags
    )
    Import-DscResource -ModuleName domainAwsDSCResources

    Node 'localhost'
    {

        dmAwsTimeSync timeZone
        {
            Ensure = 'Present'
            timeZoneName = $timeZoneName
        }

        dmAwsTagInstance applyTags
        {
            Name = 'applyTags'
            Ensure = 'Present'
            InstanceId = $instanceId
            instanceTags = $instanceTags
        }

    }

}


#Set the tags with a hashtable
$tags = @{
    name = $($env:computername)
    environment = 'myEnvironment'

}

#Splat dsc hashtable
$dscSplat = @{
    instanceTags = $tags
    instanceId = $(Invoke-RestMethod http://169.254.169.254/latest/meta-data/instance-id).Trim() #Get the instanceId from the metadata uri
    timeZoneName = 'AUS Eastern Standard Time'
}

#Create DSC MOF
myEc2Configuration @dscSplat

#Execute DSC MOF
start-dscConfiguration myEc2Configuration -verbose -wait -force


#Get the date twice to ensure the computer actually changes timezones
#The first one seems to trigger the change, the second is to confirm the change
get-date
get-date

```

***
## What Is It

Some AWS DSC Resources for managing AWS Windows EC2 Instances.


These are an open-source copy from our internal DSC resources


#### dmAwsTagInstance

Add tags to an EC2 instance



#### dmAwsTimeSync

Set the AWS TimeSync server as the NTP server

May need to run get-date to ensure timezone changes took effect

***
## Acknowledgements



<!--Bartender Link, please leave this here if you make use of this module -->
***

## Build With Bartender
> [A PowerShell Module Framework](https://github.com/DomainGroupOSS/bartender)

