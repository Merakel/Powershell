Function Check-BuildApproval
    {
    Param
        (
        [string]$application,
        [string]$newVersion,
        [string]$previousVersion
        )


    
    Class BuildValues
        {
        [string]$link
        [string]$build
        [System.Collections.ArrayList]$commitId
        [System.Collections.ArrayList]$devName
        [System.Collections.ArrayList]$ticket
        }
    $dashboard = Invoke-WebRequest "http://cruisecontrol/ccnet/ViewFarmReport.aspx"

    $applicationLink = $dashboard.links | Where-Object {$_.Outertext -eq $application} | Select-Object -expandproperty href
    $applicationLink = $applicationLink -replace "ViewProjectReport.aspx"

    $cc = Invoke-WebRequest "http://cruisecontrol$applicationLink`ViewAllBuilds.aspx"
    $buildArray = $cc.Links | Where-Object {$_.Class -eq "build-failed-link" -or $_.Class -eq "build-passed-link"} | Sort-Object -Property Outertext -Descending -Unique
    
    [string]$newBuild = $buildArray.OuterText -like "*($newVersion)*" | Sort-Object -Unique
    [string]$previousBuild = $buildArray.OuterText -like "*($previousVersion)*" | Sort-Object -Unique

    $arrayEnd = [array]::IndexOf($buildArray.OuterText,$previousBuild)
    $arrayStart = [array]::IndexOf($buildArray.OuterText,$newBuild)
   

    $links = $buildArray.href[$arrayStart..$arrayEnd]
    $linkTitles = $buildArray.OuterText[$arrayStart..$ArrayEnd]
    [System.Collections.ArrayList]$buildNumbers = @{}

    $regex = '(?<=build\.)[0-9]+'

    ForEach ($build in $links)
        {
        $matches = Select-String -InputObject $build -pattern $regex
        If(!($matches -eq $null))
            {
            [void]$buildNumbers.Add($matches.Matches.Value)
            }
        If($matches -eq $null)
            {
            [void]$buildnumbers.Add("Failed")
            }
        }

    $regex = '(?<=BugzID:\s\s?)(\w+)' #\s for additional white space... need to do double compare, check to see if bugzid shows up and then if a value is present. If not report bad formatting.
    $regex2 = 'Bugz'

    [System.Collections.ArrayList]$ticketNumbers = @{}
    [System.Collections.ArrayList]$developers = @{}
    [System.Collections.ArrayList]$commits = @{}

    
    For($n=0; $n -lt $links.count; $n++)
        {
        $invokeStage = $links[$n]
        $invoke = Invoke-WebRequest "http://cruisecontrol$invokeStage"
        
        #Get Ticket Numbers Block#
        [array]$emptyArray = ("No BugzID")
        [array]$missingArray = ("Check Build Manually")
        [array]$bugzId = select-string -InputObject $invoke.rawcontent -Pattern $regex -AllMatches | ForEach { $_.Matches } | ForEach { $_.Value } | Sort-Object -Unique
        
        If(!($bugzId -eq $null))
            {
            $ticketNumbers += , $bugzId
            }
        If($bugzId -eq $null)
            {
            [array]$bugzId2 = select-string -InputObject $invoke.rawcontent -Pattern $regex2 -AllMatches | ForEach { $_.Matches } | ForEach { $_.Value } | Sort-Object -Unique
            If(!($bugzId2 -eq $null))
                {
                $ticketNumbers += , $missingArray
                }
            If($bugzId2 -eq $null)
                {
                $ticketNumbers += , $emptyArray
                }
            }
        

        #Get Commits and Developer Names Block#
        $commitHTML = $invoke.ParsedHtml.body
        [array]$commitIds = @($commitHTML.getElementsByClassName("change-details")).id

        [string]$searchBase = $invoke.RawContent
        [System.Collections.ArrayList]$namesArray = @{}
        [System.Collections.ArrayList]$commitArray = @{}
        [array]$noCom = ("No Commits")
        [array]$noDev = ("No Developers")

        ForEach ($commit in $commitIds)
            {          
            $commit = $commit -replace "change-"
            $captureCommit = ">$commit<"
            
            $captureCommit = [regex]::Matches($searchBase, $captureCommit)

            $previousIndex = 0
            
            $lineCount = $searchBase.Substring($previousIndex, $captureCommit.Index - $previousIndex).Split("`n").Count
            $output = $searchBase.Split("`n")[$lineCount]

            $captureName = '\>(.*?)\<'
            $names = [regex]::Matches($output, $captureName)
            $names = $names -replace ">" -replace "<" -replace "[()\[\]]|\.(?!\w{3}$)", " "
            $names = (Get-Culture).textinfo.totitlecase($names.tolower())
            If ($namesArray -notcontains $names)
                {
                [void]$namesArray.Add($names)
                }
            [void]$commitArray.Add($commit)
            }

        If(!($commitIds -eq $null))
            {
            $commits += , $commitArray
            }
        If($commitIds -eq $null)
            {
            $commits += , $noCom
            $developers += , $noDev
            $namesArray = $null
            }

        If(!($namesArray -eq $null))
            {
            $developers += , $namesArray
            }
        }

    $results = @{}

    For ($n=0; $n -lt $links.count; $n++)
        {
        $t_result = New-Object BuildValues
        $t_result.Link = $links[$n]
        $t_result.Build = $buildNumbers[$n]
        $t_result.Ticket = $ticketNumbers[$n]
        $t_result.commitId = $commits[$n]
        $t_result.devName = $developers[$n]

        $results.Add($linkTitles[$n], $t_result)
        }
    $script:results = $results
    }