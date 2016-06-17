Function Compress-IISLogs
    {
    Param(
        [int]$daysOld = 90
        )
    
    #Sets location of powershell log storage, as well as email and smtp information for alerts
    $emailAddress = ""
    $smtpServer = ""

    #Gathers list of Application logs to be archived from $logFolder and places into an array for processing
    $logs = @()
    ForEach($WebSite in $(get-website))
        {
        $logFile="$($Website.logFile.directory)\w3svc$($website.id)".replace("%SystemDrive%",$env:SystemDrive)
        [array]$logs = $logs + $logfile
        }

    #Main Loop
    ForEach($log in $logs)
        {
        #Determines years of files eligible to be processe
        $yearIn = (Get-ChildItem $log -Recurse | Where-Object {$_.LastWriteTime -le (Get-Date).AddDays(-$daysOld) -and $_.extension -ne ".zip"}).LastWriteTime.Year | Sort-Object -Unique
        [array]$years = $yearIn

        #Logs if nothing is completed by script.
        If (($years.count -eq 0) -and $log.ToString())
            {
            $timeStamp = Get-Date
            Write-Output "$timeStamp - $env:computername - No files eligible for $($log | Split-Path -Leaf) to be archived."
            }

        #Subloop for files by year
        ForEach($year in $years)
            {
            #Creates source and destination files for moving files and archiving them
            $sourceFile = "$log\$year"
            $destFile = "$log\$year.zip"
        
            #Creates holding directory for files to be archived if it does not exist (script cleans up these folders, so it should not)
            If (!(Test-Path $sourceFile))
                {
                New-Item -Path $log -Name $year -ItemType Directory | Out-null
                }        
        
            #Moves files to staging folder created in previous step
            Get-Childitem -Path $log |
                Where-Object {$_.LastWriteTime.Year -eq $year} |
                Where-Object {$_.LastWriteTime -lt (get-date).AddDays(-$daysOld)} |
                Where-Object {-not $_.PsisContainer -and $_.extension -ne ".zip"} |
                Move-Item -Destination "$log\$year"

            #Loads Compression Framework, opens zip file, sets compression to optimal, and adds each file in the staging file to the archive
            #If the archive is not already created it will make a new one. Closes the zip file at the end of processing
            [void][Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
            $zip=[System.IO.Compression.ZipFile]::Open($destFile, "Update")
            $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
            $in = Get-ChildItem $sourceFile -Recurse | where {!$_.PsisContainer}| select -expand fullName
            [array]$files = $in
            ForEach ($file In $files) 
                {
                $file2 = Get-ChildItem $file | Split-Path -Leaf
                [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file,$file2,$compressionlevel)
                } 
            $zip.Dispose()
    
            #Verifies that the Zip file has been created and the source folder logs are in the archive. If true, deletes holding directory and contents and writes success message to log
            #If false, it returns failure to the log, and does not delete the holding directory. Sends email message via SMTP to notify
            $checkZip = [System.IO.Compression.zipfile]::OpenRead($destFile)
            $checkStaging = Get-ChildItem -Path $sourceFile -Name
            If (Compare-Object $checkStaging $checkZip.Entries | Where {$_.SideIndicator -eq "<="} | ForEach {$_.InputObject})
                { 
                $timeStamp = Get-Date
                Write-Output "$timeStamp - $env:computername - $($log | Split-Path -Leaf)`-$year add to archive failed. The following files: $failedZip were not compressed."
                Send-MailMessage -to $emailAddress -from "@" -subject "@PowershellWatch - IIS AutoArchive Failure" -body "$timeStamp - $($log | Split-Path -Leaf)`-$year add to archive failed. The following files: $failedZip were not compressed." -smtpserver $smtpServer
                }               
            Else
                {
                Remove-Item $sourceFile -Recurse
                $timeStamp = Get-Date
                Write-Output "$timeStamp - $env:computername - $($log | Split-Path -Leaf)`-$year added to archive successfully."
                }
        }
    }

#Creates log file if not already created
If (!(Test-Path $loggerPath))
    {
    New-Item -Path $loggerPath -ItemType Directory
    }
If (!(Test-Path $loggerPath\$loggerFile))
    {
    New-Item -Path $loggerPath -Name $loggerFile -ItemType File
    }

#Main loops which writes to log, and sends alerts if need be
ForEach($task in $tasker)
    {
    $results = (Invoke-Command -ComputerName $task.Hosts -Credential $Credential -ScriptBlock ${function:Compress-IISLogs} -ArgumentList $task.daysOld)
    }
ForEach($result in $results)
    {
    Add-Content $loggerPath\$loggerFile "$result"
    }