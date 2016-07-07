Function Get-IntranetBuilds
    {
    Param
        (
        [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
        [Int]$MasterTicket
        )
    
    $query = "SELECT TOP 1000 DATALENGTH([s]) FROM [Fogbugz].[dbo].[BugEvent] where ixBug = $master and sVerb = 'Opened'"
    $length = Invoke-SQLcmd $query -database Fogbugz -ServerInstance "pmdb"
    $query = "SELECT TOP 1000 [s] FROM [Fogbugz].[dbo].[BugEvent] where ixBug = $master and sVerb = 'Opened'"
    $ticket = Invoke-SQLcmd $query -database Fogbugz -ServerInstance "pmdb" -MaxCharLength $length.Column1
    


    [HashTable]$buildMatches = @{}
    $applicationsRegex = "(?<=.<i>)(.*)(?=</i>)"
    $buildsRegex = "((?<=$application</i> - build )(.\d+?)(?=</strong>))"
    
    $applicationsMatches = Select-String -InputObject $ticket.s -Pattern $applicationsRegex -AllMatches | ForEach { $_.Matches } | ForEach { $_.Value } 
    
    Foreach($application in $applicationsMatches){
        $buildsRegex = "(?<=$application</i> - build )(.\d+?)(?=</strong>)"

        If($application -eq "Ordering-release [Build]"){
            $buildsRegex = "(?<=$application</i> - build&nbsp;)(.*?)(?=</strong>)"
        }

        $buildsRegex = $buildsRegex -replace "\[","\[" -replace "\]","\]"
        $match = (Select-String -InputObject $ticket.s -Pattern $buildsRegex -AllMatches | ForEach { $_.Matches } | ForEach { $_.Value } )
        $buildMatches.Add($application,$match)
    }

    Return $buildMatches
}


#$fogbugzRegex = "(?<=http://fogbugz/default.asp\?)(.\d+)"
#$match = (Select-String -InputObject $ticket.s -Pattern $fogbugzRegex -AllMatches | ForEach { $_.Matches } | ForEach { $_.Value } )