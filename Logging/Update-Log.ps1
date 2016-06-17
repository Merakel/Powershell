Function Add-Log{
    [CmdletBinding()]
    PARAM( 
        [Parameter(Mandatory = $True, ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
	    [String]$Message,
        
        [Parameter(Mandatory = $False)]
        [Switch]$File,

        [Parameter(Mandatory = $False)]
        [Switch]$LogStash,

        [Parameter(Mandatory = $False)]
        [Switch]$SQL
    )

    DynamicParam{
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        If($File -eq $False -and $LogStash -eq $False){
        Write-Warning "You must select an output"
        Break
        }

        If($LogStash -eq $True){
            $LogstashHost = New-Object System.Management.Automation.ParameterAttribute
            $LogstashHost.Mandatory = $True
            $LogstashHost.ParameterSetName = 'LogParams'
            $LogstashHost.HelpMessage = "Connection info required to send logs to Logstash. Hostname or IP:"
            
            $LogstashPort = New-Object System.Management.Automation.ParameterAttribute
            $LogstashPort.Mandatory = $True
            $LogstashPort.ParameterSetName = 'LogParams'
            $LogstashPort.HelpMessage = "Connection info required to send logs to Logstash. Port:"
            $LogstashPortRange = New-Object System.Management.Automation.ValidateRangeAttribute(5000,6000)

            $logstashHostAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $logstashPortAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

            $logstashHostAttribute.Add($LogstashHost)
            $logstashPortAttribute.Add($LogstashPort)
            $logstashPortAttribute.Add($LogstashPortRange)

            $logstashHostParam = New-Object System.Management.Automation.RuntimeDefinedParameter('LogstashHost', [String], $logstashHostAttribute)
            $logstashPortParam = New-Object System.Management.Automation.RuntimeDefinedParameter('LogstashPort', [Int], $logstashPortAttribute)

            
            $paramDictionary.Add('LogstashHost', $logstashHostParam)
            $paramDictionary.Add('LogstashPort', $logstashPortParam)    
        }

        If($File -eq $True){
            $FilePath = New-Object System.Management.Automation.ParameterAttribute
            $FilePath.Mandatory = $True
            $FilePath.ParameterSetName = 'LogParams'
            $FilePath.HelpMessage = "Path to log output to required:"

            $FileName = New-Object System.Management.Automation.ParameterAttribute
            $FileName.Mandatory = $False
            $FileName.ParameterSetName = 'LogParams'
            $FileName.HelpMessage = "Name of Logfile. If not supplied, defaults to application name with short date appened to the end:"

            $filePathAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $fileNameAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]


            $filePathAttribute.Add($FilePath)
            $fileNameAttribute.Add($FileName)

            $filePathParam = New-Object System.Management.Automation.RuntimeDefinedParameter('FilePath', [String], $filePathAttribute)
            $fileNameParam = New-Object System.Management.Automation.RuntimeDefinedParameter('FileName', [String], $fileNameAttribute)
 
            $paramDictionary.Add('FilePath', $filePathParam)
            $paramDictionary.Add('FileName', $fileNameParam)   
        }

        Switch($SQL){
            $True{
                $LogLevel = New-Object System.Management.Automation.ParameterAttribute
                $LogLevel.Mandatory = $True
                $LogLevel.ParameterSetName = 'LogParams'
                $LogLevel.HelpMessage = "Level of the message being logged. WARN, DEBUG or FATAL are available options:"
                $LogLevelSet = New-Object System.Management.Automation.ValidateSetAttribute("WARN","DEBUG","FATAL")

                $GUIDAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute] 

                $logLevelAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

                $logLevelAttribute.Add($LogLevel)
                $logLevelAttribute.Add($LogLevelSet)
                $GUIDAttribute.Add($GUID)

                $logLevelParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Level', [String], $logLevelAttribute)
                $GUIDParam = New-Object System.Management.Automation.RuntimeDefinedParameter('GUID', [String], $GUIDAttribute)

                $paramDictionary.Add('Level', $logLevelParam)
                $paramDictionary.Add('GUID', $GUIDAttribute)
            }
            $False{
                $ApplicationName = New-Object System.Management.Automation.ParameterAttribute
                $ApplicationName.Mandatory = $True
                $ApplicationName.ParameterSetName = 'LogParams'
                $ApplicationName.HelpMessage = "Name of the Application or Script:"

                $InvokeLocation = New-Object System.Management.Automation.ParameterAttribute
                $InvokeLocation.Mandatory = $True
                $InvokeLocation.ParameterSetName = 'LogParams'
                $InvokeLocation.HelpMessage = "Location the Script or Application is be run from:"

                $RunningLocation = New-Object System.Management.Automation.ParameterAttribute
                $RunningLocation.Mandatory = $True
                $RunningLocation.ParameterSetName = 'LogParams'
                $RunningLocation.HelpMessage = "Location the Script or Application is be run on:"

                $LogLevel = New-Object System.Management.Automation.ParameterAttribute
                $LogLevel.Mandatory = $True
                $LogLevel.ParameterSetName = 'LogParams'
                $LogLevel.HelpMessage = "Level of the message being logged. WARN, DEBUG or FATAL are available options:"
                $LogLevelSet = New-Object System.Management.Automation.ValidateSetAttribute("WARN","DEBUG","FATAL")

                $Environment = New-Object System.Management.Automation.ParameterAttribute
                $Environment.Mandatory = $True
                $Environment.ParameterSetName = 'LogParams'
                $Environment.HelpMessage = "Environment that the logfile pertains to. PROD, DEV, QA or RC are available options:"
                $EnvironmentSet = New-Object System.Management.Automation.ValidateSetAttribute("PROD","DEV","QA","RC")

                $Tags = New-Object System.Management.Automation.ParameterAttribute
                $Tags.Mandatory = $False
                $Tags.ParameterSetName = 'LogParams'
                $Tags.HelpMessage = "Tags for Elastic. Output should be in array format:"

                $GUID = New-Object System.Management.Automation.ParameterAttribute
                $GUID.Mandatory = $False
                $GUID.ParameterSetName = 'LogParams'
                $GUID.HelpMessage = "SQL GUID for Parameter Reference:"

                $applicationNameAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $invokeLocationAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $runningLocationAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $logLevelAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $environmentAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $tagsAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]        
                
                $applicationNameAttribute.Add($ApplicationName)
                $invokeLocationAttribute.Add($InvokeLocation)
                $runningLocationAttribute.Add($RunningLocation)
                $logLevelAttribute.Add($LogLevel)
                $logLevelAttribute.Add($LogLevelSet)
                $environmentAttribute.Add($Environment)
                $environmentAttribute.Add($EnvironmentSet)
                $tagsAttribute.Add($Tags)

                $applicationNameParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ApplicationName', [String], $applicationNameAttribute)
                $invokeLocationParam = New-Object System.Management.Automation.RuntimeDefinedParameter('InvokeLocation', [String], $invokeLocationAttribute)
                $runningLocationParam = New-Object System.Management.Automation.RuntimeDefinedParameter('RunningLocation', [String], $runningLocationAttribute)
                $logLevelParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Level', [String], $logLevelAttribute)
                $environmentParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Environment', [String], $environmentAttribute)
                $tagsParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Tags', [Array], $tagsAttribute)

                $paramDictionary.Add('ApplicationName', $applicationNameParam)
                $paramDictionary.Add('InvokeLocation', $invokeLocationParam)
                $paramDictionary.Add('RunningLocation', $runningLocationParam)
                $paramDictionary.Add('Level', $logLevelParam)
                $paramDictionary.Add('Environment', $environmentParam)
                $paramDictionary.Add('Tags', $tagsParam)
            }
        }

        Return $paramDictionary
        }

    Begin{
        If($Logstash){                   
            [System.Collections.ArrayList]$logstashOutput = @()
            
            $runSpacePool = [RunSpaceFactory]::CreateRunspacePool(1, 5)
            $runSpacePool.Open()
            
            $flags= @{"computername" = $PSBoundParameters.LogstashHost ; "count" = "3"}
            $pipeline = [powershell]::Create().AddCommand("Test-Connection")

            Foreach($f in $flags.keys){
                     $pipeline.AddParameter($f, $flags.$f) | Out-Null
                     }

            $pipeline.RunSpacePool = $runSpacePool #This sets the RunSpacePool to execute our current pipeline
            $status = $pipeline.BeginInvoke() #This executes the RunSpacePool we just currently created.
        
            $job = "" | Select-Object Status, Pipeline
            $job.Status = $status
            $job.Pipeline = $pipeline
        }
        
        If($File){

            [System.Collections.ArrayList]$fileOutput = @()
            $logTimestamp = Get-Date -Format MM.dd.yyyy
            Switch($PSBoundParameters.FileName){
                {!$Null}{
                    $logFile = ($PSBoundParameters.FileName + ".log")
                }
                $Null{
                    $logFile = ($PSBoundParameters.ApplicationName + ".$logTimestamp.log")
                }
            }
            
            $pathExists = Test-Path $PSBoundParameters.FilePath

            Switch($pathExists){
                $True{
                    $fileExists = Test-Path ($PSBoundParameters.FilePath + "\" + $logFile)
                    Switch($fileExists){
                        $True{
                            Write-Warning "Logfile already exists, appending to log."
                            $logExists = $True
                        }
                        $False{
                            Write-Warning "Logfile does not exists, creating new log"
                            $logExists = $False
                        }

                    }
                }
                $False{
                    Write-Warning "Log Directory does not exist."
                    Break
                }
            }
        }

        $logTimestamp = Get-Date -Format o
    }

    Process{
        If($LogStash){
            $jsonObject = (
                New-Object PSObject | 
                Add-Member -passThru NoteProperty log_timestamp $logTimestamp |
                Add-Member -PassThru NoteProperty application_name $PSBoundParameters.ApplicationName | 
                Add-Member -PassThru NoteProperty invoke_location $PSBoundParameters.InvokeLocation |
                Add-Member -PassThru NoteProperty running_location $PSBoundParameters.RunningLocation |
                Add-Member -PassThru NoteProperty level $PSBoundParameters.Level |
                Add-Member -PassThru NoteProperty environment $PSBoundParameters.Environment | 
                Add-Member -PassThru NoteProperty message $Message |
                Add-Member -PassThru NoteProperty tags $PSBoundParameters.Tags) |
                ConvertTo-Json

            $logstashOutput += $jsonObject
            }
        
        If($File){
            $output = "$logTimestamp" + "|"+$PSBoundParameters.RunningLocation + "|" + $PSBoundParameters.InvokeLocation +`
            ,"|[" + $PSBoundParameters.Environment + "][" + $PSBoundParameters.Level + "]|" + " $Message"

            $fileOutput += $output
            }
    }

    End{
        While (@($job | Where-Object {$_.Status-ne $Null}).count -gt 0){
            If($job.Status.IsCompleted -eq $True){
                $data += $job.Pipeline.EndInvoke($job.Status)
                $job.Pipeline.Dispose()
                $job.Status= $Null
                $job.Pipeline= $Null
            }
        }

        If($LogStash){
            ForEach($log in $logstashOutput){
                Write-Warning $log
                }
        }

        If($File){
            Switch($logExists){
                $True{
                ForEach($log in $fileOutput){
                    Add-Content ($PSBoundParameters.FilePath + "\" + $logFile) $log
                    }
                }
                $False{
                    New-Item ($PSBoundParameters.FilePath + "\" + $logFile) -type File
                    ForEach($log in $fileOutput){
                        Add-Content ($PSBoundParameters.FilePath + "\" + $logFile) $log
                    }
                }
            }
        }
    
    Return $fileExists
    }
}
