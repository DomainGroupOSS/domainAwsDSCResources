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