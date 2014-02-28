﻿
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Set-TweetToken
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $APIKey,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $APISecret,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [string]
        $AccessToken,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [string]
        $AccessTokenSecret
    )

    Begin
    {
    }
    Process
    {
        $TokenHash = @{
            APIKey = $APIKey
            APISecret = $APISecret
            AccessToken = $AccessToken
            AccessTokenSecret = $AccessTokenSecret
        }
        
        $ConfigAsJson = ConvertTo-Json -InputObject $TokenHash -Compress
        $FolderName = "Posh-Tweet"
        $ConfigName = "config.json"
        
        if (!(Test-Path "$($env:AppData)\$FolderName"))
        {
            Write-Verbose -Message "Seems this is the first time the config has been set."
            Write-Verbose -Message "Creating folder $("$($env:AppData)\$FolderName")"
            New-Item -ItemType directory -Path "$($env:AppData)\$FolderName" | Out-Null
        }
        
        Write-Verbose -Message "Saving the information to configuration file $("$($env:AppData)\$FolderName\$ConfigName")"
        "$($ConfigAsJson)"  | Set-Content  "$($env:AppData)\$FolderName\$ConfigName" -Force
        
    }
    End
    {
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Connect-TweetService
{
    [CmdletBinding()]
    [OutputType([HigLabo.Net.Twitter.TwitterClient])]
    Param()

    Begin
    {
        # Test if configuration file exists.
        if (!(Test-Path "$($env:AppData)\Posh-Tweet\config.json"))
        {
            throw "Configuration has not been set, Set-TweetTokens to configure the API Tokens."
        }
    }
    Process
    {
        $Config = Get-Content -Path "$($env:AppData)\Posh-Tweet\config.json"
        $ConfigObj = $Config | ConvertFrom-Json
        $TwitterClient = New-Object HigLabo.Net.Twitter.TwitterClient($ConfigObj.APIKey,
                                                                      $ConfigObj.APISecret,
                                                                      $ConfigObj.AccessToken,
                                                                      $ConfigObj.AccessTokenSecret)

        # Save client instance in to a variable other functions can use.
        $Global:TweetInstance = $TwitterClient
        
        $TwitterClient
    }
    End
    {
    }
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TweetAccountSetting
{
    [CmdletBinding()]
    [OutputType([psobject])]
    Param()

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }
    }
    Process
    {
        $AccountSettingResponse = $TwClient.GetAccountSettings()
        $JSONPSCustom = $AccountSettingResponse.JsonText | ConvertFrom-Json
        $JSONPSCustom.pstypenames.insert(0,'Tweet.Account.Setting')
        $JSONPSCustom
    }
    End
    {
    }
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TweetApplicationRateLimit
{
    [CmdletBinding()]
    [OutputType([psobject])]
    Param()

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }
    }
    Process
    {
        $AppLimitResult = $TwClient.GetApplicationRateLimitStatus()
        $JSONPSCustom = $AppLimitResult.JsonText | ConvertFrom-Json
        $JSONPSCustom.pstypenames.insert(0,'Tweet.Application.Limit')
        $JSONPSCustom
    }
    End
    {
    }
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Returns a collection of the most recent Tweets and retweets posted by the 
   authenticating user and the users they follow.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Send-Tweet
{
    [CmdletBinding()]
    [OutputType([psobject])]
    Param
    (
        # Twitter message to send. Limit of 140 charecters.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateLength(1,140)]
        [string]
        $Message
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }
    }
    Process
    {
        $TweetResult = $TwClient.UpdateStatus($Message)
        $JSONPSCustom = $TweetResult.JsonText | ConvertFrom-Json
        $JSONPSCustom.pstypenames.insert(0,'Tweet.Message')
        $JSONPSCustom
    }
    End
    {
    }
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TweetTimeline
{
    [CmdletBinding()]
    [OutputType([psobject])]
    Param
    (
        # Specifies the number of records to retrieve. Must be less than or equal to 200. Defaults to 20.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $Count,

        # This parameter will prevent replies from appearing in the returned timeline. 
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $ExcludeReplies
    )

    Begin
    {
        if (!(Test-Path variable:Global:TweetInstance ))
        {
            throw "No connection present."
        }
        else
        {
            $TwClient = $Global:TweetInstance
        }

        $TimelineOptions = new-object HigLabo.Net.Twitter.GetHomeTimelineCommand
    }
    Process
    {
        if ($Count)
        {
            $TimelineOptions.Count = $Count
        }

        if ($ExcludeReplies)
        {
            $TimelineOptions.ExcludeReplies = 'true'
        }


        $TimelineResult = $TwClient.GetHomeTimeline($TimelineOptions)
        foreach($Message in $TimelineResult)
        {
            $Message
        }

        #$JSONPSCustom = $TweetResult.JsonText | ConvertFrom-Json
        #$JSONPSCustom.pstypenames.insert(0,'Tweet.Message')
        #$JSONPSCustom
    }
    End
    {
    }
}