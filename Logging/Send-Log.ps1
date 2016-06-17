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