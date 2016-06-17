Function Send-Heartbeat { 
    PARAM ( 
        [ValidateNotNullOrEmpty()] 
        [string]$Logstash, 
        [int]$Port 
    )        

    #Create Endpoint
    $Ip = [System.Net.Dns]::GetHostAddresses($LogStash) | Where-Object {$_.AddressFamily -eq 'InterNetwork'}
    $Address = [System.Net.IPAddress]::Parse($Ip)
    $endPoint = New-Object System.Net.IPEndPoint $Address, $Port


    #Create Socket
    $addressFamily = [System.Net.Sockets.AddressFamily]::InterNetwork  
    $datagram = [System.Net.Sockets.SocketType]::Dgram  
    $protocol = [System.Net.Sockets.ProtocolType]::UDP
    $socket = New-Object System.Net.Sockets.Socket $addressFamily, $datagram, $protocol   
    $socket.TTL = 32 

    #Connect to Socket
    $socket.Connect($endPoint)

    #Encoding
    $message = "$Logstash"
    $encoding = [System.Text.Encoding]::UTF8
    $buffer = $encoding.GetBytes($message)

    #Send Buffer
    [void]::($socket.Send($buffer))
    }

Function Get-Heartbeat {
    PARAM (
        [ValidateNotNullOrEmpty()] 
        [hashtable]$LogStash,
        [int]$LogStashPort = 5015,
        [int]$TTL = 1
    )
    
    
    $heartbeat = @{}
    $script:results = @{}
            
        ForEach($key in $Logstash.keys)
        {
        $counter = 0
        $continue = $false
        $logStashHost = $key
        $listenPort = $LogStash.$key
        
        Do{
                
            $Runspace = [RunSpaceFactory]::CreateRunspace()
            $PowerShell = [PowerShell]::Create()
            $PowerShell.Runspace = $Runspace
            $Runspace.Open()

            $port = @{"Remote" = "$listenPort"}

            [void]$PowerShell.AddScript(
                {
                PARAM ($port)
                $hostname = $env:COMPUTERNAME
                $ip = [System.Net.Dns]::GetHostAddresses($hostname) | Where-Object {$_.AddressFamily -eq 'InterNetwork'}
                $address = [System.Net.IPAddress]::Parse($ip)
                $listener = New-Object System.Net.IPEndPoint ($address,$port.remote)
                $udpclient = New-Object System.Net.Sockets.UdpClient $port.remote
                $udpclient.Client.ReceiveTimeout = 5000
                $udpclient.Client.SendTimeout = 5000
                $content = $udpclient.Receive([ref]$listener)
                [Text.Encoding]::UTF8.GetString($content)
                $udpclient.close()}
                ).AddArgument($port)
            
            $Async = $PowerShell.BeginInvoke()
            
            Send-Heartbeat -Logstash $logStashHost -Port $LogStashPort         

            $Data = $PowerShell.EndInvoke($Async)
            
            $hashtable = @{}    
            
            $remote = $data -split ','
            $remote = $remote -replace "`"",""
            $remote = $remote[0] -replace "{",""
            $remote = ($remote -split ':')[1]
            If($remote -ne $null)
                {
                $hashtable.add($remote,"Heartbeat")
                }
            If($remote -eq $null)
                {
                $hashtable.add($logStashHost,"Timedout")
                }
            
            $PowerShell.Dispose()

            $data = $null
            $counter++

            If($hashtable.$logStashHost -eq "Heartbeat" -or $counter -gt $TTL)
                {
                If($counter -gt $TTL)
                    {
                    If(!($results.ContainsKey($logStashHost)))
                        {
                        If($logStashHost -in $LogStash.keys)
                            {
                            $heartbeat.add($logStashHost,"Timedout")
                            }
                        If(!($logStashHost -in $LogStash.keys))
                            {
                            $heartbeat.add($Remote,"N/A")
                            }
                        }
                    }
               If($hashtable.$logStashHost -eq "Heartbeat")
                    {
                    If(!($results.ContainsKey($logStashHost)))
                        {
                        $heartbeat.add($logStashHost,$hashtable.$logStashHost)
                        }
                    If($results.$logStashHost -eq "Timedout")
                        {
                        $heartbeat.Remove($logStashHost)
                        $heartbeat.add($logStashHost,$hashtable.$logStashHost)
                        }
                    }
                $continue = $true
                }
            } Until ($continue -eq $true)
        }
        $script:results += $heartbeat
        $Runspace.Close()
    }
}

Function Get-ElasticStatus{
    Param([Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]$Servers)
    Begin{
        $errorTable = @{}
        $healthCheck = @{}
        [system.collections.arraylist]$serverTable = @()
    }

    Process{
        If(!($Servers.GetType().Name -match 'Hashtable')){
            $convert = $Servers
            $Servers = @{}
            ForEach($c in $convert){
                $Servers.add("$c","N/A")
            }
        }
        ForEach($server in $Servers.Keys){
            $cluster = $null
            $health = $null
            Try{
                $cluster = Invoke-WebRequest "http://$server`:9200/_cluster/health?pretty=true:9200/_cluster/health?pretty=true" -ErrorAction Stop
                $health = ConvertFrom-Json $cluster.content -ErrorAction Stop
                }
            Catch{ 
                $warning = $_.exception.message + ": $Server"
                Write-Warning $warning
                }
            Finally{
                $healthCheck.add("$server status",$health.status)
                $healthCheck.add("$server timed_out",$health.timed_out)
                $healthCheck.add("$server status_code",$cluster.statuscode)
                $serverTable += $server
                }
            }
        }

    End {
        ForEach($server in $serverTable){
            $errors = @()
            If($healthCheck."$server status" -eq "red"){
                $errors += "{Cluster Status is Red}"
            }
            If($healthCheck."$server timed_out" -eq $True){
                $errors += "{Cluster timed out}"
            }
            If($healthCheck."$server status_code" -ne 200){
                $errors += "{HTTP Response code is not 200}"
            }
            If($healthCheck."$server status"  -eq $null){
                $errors += "{Cannot get Cluster-Status: Timeout}"
            }
            If($healthCheck."$server timed_out"  -eq $null){
                $errors += "{Cannot get Cluster-Timed_out: Timeout}"
            }
            If($healthCheck."$server status_code"  -eq $null){
                $errors += "{Cannot get Status Code: Timeout}"
            }
            If($errors -ne $null){
                $errorTable.Add($server,($errors | Out-String))
            }
        }
        Return $errorTable    
    }
}

$servers = @{}
$body = $servers | Get-ElasticStatus

$emailAddress = 
$smtpServer = 

If($body){
    Send-MailMessage -to $emailAddress -from  -subject "@PowershellWatch - Elastic Status: A Critical Error has Occured" -bodyasHTML ($test.GetEnumerator() | ConvertTo-Html -Property Name,Value -Head "<html><h2>The following servers are experiencing issues:</h2><br></html>" | Out-String) -smtpserver $smtpServer
    }

#LogStash Settings
#-----------------
#Input:
#udp {
#   port => 5015
#   type => "heartbeat"
#   }
#
#Output:
#if [type] == "heartbeat" {
#   udp {
#	   host => 
#	   port => 5016
#	}