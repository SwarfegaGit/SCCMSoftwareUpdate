function Get-SCCMSoftwareUpdate {
    [CmdletBinding()]
    param (
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    Begin {
    }

    Process {

        ($ComputerName).ForEach({

            $Computer = $PSItem

            Try {
                Write-Verbose -Message "[$ComputerName]: Searching available for updates"
                $Query = Get-WmiObject -Query "SELECT * FROM CCM_SoftwareUpdate" -Namespace "ROOT\ccm\ClientSDK" -ComputerName $Computer -ErrorAction Stop                    
            }
            Catch {
                Write-Warning -Message "[$ComputerName]: Error occured querying computer"
            }

            If ($null -eq $Query) {
                Write-Verbose -Message "[$ComputerName]: No software update(s) found"
            }
            Else {
                $Query | ForEach-Object {

                    $EvaluationState = switch ($PSItem.EvaluationState) {
                        0 {'PendingInstall'} 
                        3 {'Detecting'} 
                        5 {'Downloading'} 
                        6 {'AwaitingInstall'} 
                        7 {'Installing'} 
                        11 {'Verifying'} 
                        8 {'PendingReboot'}
                        9 {'PendingReboot'}
                        10 {'PendingReboot'}
                        12 {'InstallComplete'} 
                        13 {'Failed'} 
                        default {'Unknown'}
                    }

                    [PSCustomObject] @{
                        PSTypeName = 'XV5.AJP.SCCM.SoftwareUpdate.Get'
                        ArticleID = $PSItem.ArticleID
                        BulletinID = $PSItem.BulletinID
                        ComplianceState = $PSItem.ComplianceState
                        ContentSize = $PSItem.ContentSize
                        Deadline = $PSItem.Deadline
                        Description = $PSItem.Description
                        ErrorCode = $PSItem.ErrorCode
                        EstimatedInstallTime = $PSItem.EstimatedInstallTime
                        EvaluationState = $PSItem.EvaluationState
                        ExclusiveUpdate = $PSItem.ExclusiveUpdate
                        FullName = $PSItem.FullName
                        IsUpgrade = $PSItem.IsUpgrade
                        MaxExecutionTime = $PSItem.MaxExecutionTime
                        Name = $PSItem.Name
                        NextUserScheduledTime = $PSItem.NextUserScheduledTime
                        NotifyUser = $PSItem.NotifyUser
                        OverrideServiceWindows = $PSItem.OverrideServiceWindows
                        PercentComplete = $PSItem.PercentComplete
                        Publisher = $PSItem.Publisher
                        RebootOutsideServiceWindows = $PSItem.RebootOutsideServiceWindows
                        RestartDeadline = $PSItem.RestartDeadline
                        StartTime = $PSItem.StartTime
                        Type = $PSItem.Type
                        UpdateID = $PSItem.UpdateID
                        URL = $PSItem.URL
                        UserUIExperience = $PSItem.UserUIExperience
                        ComputerName = $Computer
                    }

                }

            }

        }) # End ComputerName ForEach
    
    } # End Process

    End {
    }

} # End Function

function Install-SCCMSoftwareUpdate {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Alias('PSComputerName')]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        $ArticleID

    )

    Begin {
    }

    Process {

        Try {

            If ($null -eq $ArticleID) {

                Write-Verbose -Message "[$ComputerName]: Searching available for updates"
                $Query = Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate -ComputerName $ComputerName -ErrorAction Stop
                Write-Verbose -Message "[$ComputerName]: $(($Query).Count) updates found"
                $Result = Invoke-WmiMethod -Class CCM_SoftwareUpdatesManager -Name InstallUpdates -ArgumentList (,$Query) -Namespace root\ccm\clientsdk -ComputerName $ComputerName
                [PSCustomObject]@{
                    ComputerName = $ComputerName
                    ArticleID = $ArticleID
                    Success = If ($Result.ReturnValue -eq '0') { $true } else { $false }
                }

            } Else {

                Write-Verbose -Message "[$ComputerName]: Searching for update KB$ArticleID"
                $Query = Get-WmiObject -Namespace "root\ccm\clientSDK"-Query "SELECT * FROM CCM_SoftwareUpdate WHERE ArticleID='$ArticleID'" -ComputerName $ComputerName -ErrorAction Stop
                If ($null -eq $Query) {
                    Write-Warning -Message "[$ComputerName]: KB$ArticleID not found"
                } Else {
                    Write-Verbose -Message "[$ComputerName]: KB$ArticleID update found. Invoking installation"
                    Invoke-WmiMethod -Class CCM_SoftwareUpdatesManager -Name InstallUpdates -ArgumentList (,$Query) -Namespace root\ccm\clientsdk -ComputerName $ComputerName
                }
                [PSCustomObject]@{
                    ComputerName = $ComputerName
                    ArticleID = $ArticleID
                    Success = If ($Result.ReturnValue -eq '0') { $true } else { $false }
                }

            }

        } Catch {

            Write-Warning -Message "[$ComputerName]: KB$ArticleID failed to install"          

        }

    }

    End {
    }

}