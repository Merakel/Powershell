$webList = Get-Website | Select-Object name -ExpandProperty name
$logExtFileFlags = "Date,Time,ClientIP,UserName,SiteName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,BytesSent,BytesRecv,TimeTaken,ServerPort,UserAgent,Cookie,Referer,ProtocolVersion,Host,HttpSubStatus"
$i = 1

ForEach($site in $webList)
    {
    Set-ItemProperty "IIS:\Sites\$site" -name logfile -value @{logExtFileFlags=$logExtFileFlags}
    Write-Host $i,":",$site,": Updated"
    $i++
    }

$displayList = @{}

ForEach($site in $webList)
    {
    $display = Get-ItemProperty "IIS:\Sites\$site" -name logfile | Select-Object logExtFileFlags -ExpandProperty logExtFileFlags
    $displayList += @{"$site" = "$display"}
    }