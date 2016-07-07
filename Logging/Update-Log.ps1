Function Add-Log{
    [CmdletBinding()]
    PARAM( 
        [Parameter(Mandatory = $True, ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
	    [String]$Message,
        
        [Parameter(Mandatory = $True, ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("INFO", "DEBUG", "WARN", "FATAL")]
	    [String]$Level,

        [Parameter(Mandatory = $False)]
        [Switch]$UID,

        [Parameter(Mandatory = $False)]
        [Switch]$File,

        [Parameter(Mandatory = $False)]
        [Switch]$LogStash,

        [Parameter(Mandatory = $False)]
        [Switch]$SQL,

        [Parameter(Mandatory = $False)]
        [Switch]$Debugger
    )

    DynamicParam{
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        If($File -eq $False -and $LogStash -eq $False -and $Debug -eq $False){
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
                $GUID = New-Object System.Management.Automation.ParameterAttribute
                $GUID.Mandatory = $True
                $GUID.ParameterSetName = 'LogParams'
                $GUID.HelpMessage = "GUID associated with this Applications Saved Logging Paramaters:"

                $GUIDAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute] 

                $GUIDAttribute.Add($GUID)

                $GUIDParam = New-Object System.Management.Automation.RuntimeDefinedParameter('GUID', [String], $GUIDAttribute)

                $paramDictionary.Add('Level', $logLevelParam)
                $paramDictionary.Add('GUID', $GUIDAttribute)
            }
            $False{
                $ApplicationName = New-Object System.Management.Automation.ParameterAttribute
                $ApplicationName.Mandatory = $True
                $ApplicationName.ParameterSetName = 'LogParams'
                $ApplicationName.HelpMessage = "Name of the Application or Script:"

                $RunningLocation = New-Object System.Management.Automation.ParameterAttribute
                $RunningLocation.Mandatory = $True
                $RunningLocation.ParameterSetName = 'LogParams'
                $RunningLocation.HelpMessage = "Location the Script or Application is be run on:"

                $Environment = New-Object System.Management.Automation.ParameterAttribute
                $Environment.Mandatory = $True
                $Environment.ParameterSetName = 'LogParams'
                $Environment.HelpMessage = "Environment that the logfile pertains to. PROD, DEV, QA or RC are available options:"
                $EnvironmentSet = New-Object System.Management.Automation.ValidateSetAttribute("PROD","DEV","QA","RC")

                $Tags = New-Object System.Management.Automation.ParameterAttribute
                $Tags.Mandatory = $False
                $Tags.ParameterSetName = 'LogParams'
                $Tags.HelpMessage = "Tags for Elastic. Output should be in array format:"

                $applicationNameAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $runningLocationAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $environmentAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $tagsAttribute = New-Object System.Collections.ObjectModel.Collection[System.Attribute]        
                
                $applicationNameAttribute.Add($ApplicationName)
                $runningLocationAttribute.Add($RunningLocation)
                $environmentAttribute.Add($Environment)
                $environmentAttribute.Add($EnvironmentSet)
                $tagsAttribute.Add($Tags)

                $applicationNameParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ApplicationName', [String], $applicationNameAttribute)
                $runningLocationParam = New-Object System.Management.Automation.RuntimeDefinedParameter('RunningLocation', [String], $runningLocationAttribute)
                $environmentParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Environment', [String], $environmentAttribute)
                $tagsParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Tags', [Array], $tagsAttribute)

                $paramDictionary.Add('ApplicationName', $applicationNameParam)
                $paramDictionary.Add('RunningLocation', $runningLocationParam)
                $paramDictionary.Add('Environment', $environmentParam)
                $paramDictionary.Add('Tags', $tagsParam)
            }
        }

        Return $paramDictionary
        }

    Begin{
        [System.Collections.ArrayList]$fileOutput = @()
        [System.Collections.ArrayList]$logstashOutput = @()
        
        If($File){
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

        $logTimestamp = Get-Date -Format yyyy-mm-ddTHH:MM:ss.ffzzzz
    }

    Process{

        [Hashtable]$logParameters = @{}

        Foreach($param in $PSBoundParameters.Keys){
            If($PSBoundParameters.$Param -eq "IsPresent"){
                Write-Host Hi
            }
            Else{
                $logParameters.Add($param.ToLower(),$PSBoundParameters.$Param)
            }
        }
         
        If($LogStash){
            $jsonObject = New-Object PSObject
                Foreach($param in $logParameters.Keys){
                    $jsonObject | Add-Member -passThru NoteProperty $param $logParameters.$param
                }
            $logstashOutput += $jsonObject | ConvertTo-Json
            }
        
        If($File -or $Debugger){
            $output = "$logTimestamp" + "|"+$PSBoundParameters.RunningLocation +`
            ,"|[" + $PSBoundParameters.Environment + "][" + $PSBoundParameters.Level + "]|" + "$Message"

            $fileOutput += $output
            }
    }

    End{
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

        If($Debugger){
            ForEach($log in $fileOutput){
                Write-Warning $log
            }
        }
    }
}

Function Send-Log{
    [CmdletBinding()] 
    PARAM(
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()] 
        [String]$Logstash, 
        
        [Parameter(Mandatory = $True, Position = 2)]
        [ValidateNotNullOrEmpty()] 
        [Int]$Port,
        
        [Parameter(Mandatory = $True, ValueFromPipeline=$True, Position = 3)]
        [ValidateNotNullOrEmpty()] 
        $JsonObject
    )        
    Begin{
        #Create Endpoint
        $Ip = [System.Net.Dns]::GetHostAddresses($LogStash) 
        $Address = [System.Net.IPAddress]::Parse($Ip)
        $endPoint = New-Object System.Net.IPEndPoint $Address, $Port


        #Create Socket
        $addressFamily = [System.Net.Sockets.AddressFamily]::InterNetwork  
        $datagram = [System.Net.Sockets.SocketType]::Dgram  
        $protocol = [System.Net.Sockets.ProtocolType]::UDP
        $socket = New-Object System.Net.Sockets.Socket $addressFamily, $datagram, $protocol   
        $socket.TTL = 32 
    }

    Process{
        #Connect to Socket
        $socket.Connect($endPoint)

        #Encoding
        $encoding = [System.Text.Encoding]::UTF8
        $buffer = $encoding.GetBytes($JsonObject)

        #Send Buffer
        [void]::($socket.Send($buffer))
    }

    End{
        Write-Verbose "Send Complete"   
    } 
}