Function Add-IntranetDeployScript{
    Param
        (
        [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
        [HashTable]$buildMatches,

        [Parameter(Mandatory=$true)]
        [DateTime]$date
        )

#region declareVariables
[HashTable]$output = @{}
[HashTable]$deployParams = @{}
[HashTable]$remoteParams = @{}
[HashTable]$rcParams = @{}
[String]$unknownBuilds = $null
[String]$iList = $null
[String]$diList = $null
[String]$pList = $null
[String]$dpList = $null
[String]$eList = $null
[String]$deList = $null
[String]$sList = $null
[String]$dsList = $null
[String]$uList = $null
[String]$duList = $null
[String]$eomsList = $null
[String]$deomsList = $null
[String]$oList = $null
[String]$doList = $null
[String]$rList = $null
#endregion declareVariables

#region lookupLists
$appList = @{
"Intranet.Firstcut" = "Intranet.Firstcut";
"Intranet.Protolabs" = "Intranet.Protolabs";
"intranet.protomold-master [Build]" = "Intranet.Protomold";
"PricingService-master [Build]" = "Pricing.CalculationService","Pricing.Web","Pricing.Web.Public";
"Enterprise-Customer-master [Build]" = "DeniedPartyService","EnterpriseCustomer.Web","EnterpriseCustomerService";
"FCQueue-master [Build]" = "FCQDisplay", "FCQService";
"Finance.TaxService-master [Build]" = "Finance.TaxService";
"Shipping.Service-master [Build] " = "Shipping.Service";
"AXAdapter-master [Build]" = "AXAdapter";
"FCAutoquote" = "fcautoquote";
"Fineline-Integration-Master [Build]" = "FineLineIntegrationService";
"CommercePlatform-master [Build]" = "CashSite";
"Ordering-release [Build]" = "OrderAggregationService","OrderSite";
"OrderService.Web-master [Build]" = "OrderService.Web";
"BusinessObjects" = "BusinessObjects"
}

$envList = @{
}

$svrList = @{
"EnterpriseCustomerService" = "APPP1SVRUS";
"OrderAggregationService" = "APPP1SVRUS";
}

$rmtList = @{
"AXAdapter" = "DOA-UK";
}

$grpList = @{
"Intranets" = "Intranet.Firstcut","Intranet.Protolabs","Intranet.Protomold";
"Pricing" = "Pricing.CalculationService","Pricing.ExportService","Pricing.Web","Pricing.Web.Public";
"Enterprise Customer" = "DeniedPartyService","EnterpriseCustomer.Web","EnterpriseCustomerService";
"Services" = "FCQDisplay", "FCQService","Finance.TaxService","Shipping.Service";
"Util Apps" = "axaadapter","fcautoquote","FineLineIntegrationService"
"EOMS" = "CashSite","OrderAggregationService","OrderSite","OrderService.Web"
"Other" = "BusinessObjects"
}
#endregion lookupLists

#region checkBuilds
[void][Reflection.Assembly]::LoadWithPartialName("PresentationCore")
[void][Reflection.Assembly]::LoadWithPartialName("PresentationFramework")
ForEach($build in $buildMatches.Keys){
    If(!($appList.ContainsKey($build))){
        If($unknownBuilds){
            $unknownBuilds += ", " + $build
            }
        Else{
            $unknownBuilds += $build
        }
    }
}

If($unknownBuilds){
    $ButtonType = [System.Windows.MessageBoxButton]::Ok
    $MessageboxTitle = “Unknown Builds”
    $Messageboxbody = “The following builds are not expected:`n$unknownBuilds`nUpdate Lookups Region to Continue”
    $MessageIcon = [System.Windows.MessageBoxImage]::Warning
    [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
    Break
}
#endregion checkBuilds

#region buildScripts
ForEach($build in $buildMatches.Keys){
    ForEach($a in $appList.$build){
        Write-Warning $a
        $b = $buildMatches.$build
        
        $c = Foreach($Key in ($envList.GetEnumerator() | Where-Object {$_.Value -eq $a})){
            $Key.name
        }
        $d = Foreach($Key in ($svrList.GetEnumerator() | Where-Object {$_.Value -eq $a})){
            $Key.name
        }
        $e = Foreach($Key in ($grpList.GetEnumerator() | Where-Object {$_.Value -eq $a})){
            $Key.name
        }
        $f = Foreach($Key in ($rmtList.GetEnumerator() | Where-Object {$_.Value -eq $a})){
            $Key.name
        }
    
        If(!$c){
            $c = "PROD-US"
        }        
        If(!$d){
            $d = "WEBP1SVRUS,WEBP2SVRUS"
        }
        If(!$f){
            $f = "DOA-UK,DOA-JP"
        }
        $appParam = New-Object PSObject
        $appParam | Add-Member -type NoteProperty -Name 'Build' -Value $b
        $appParam | Add-Member -type NoteProperty -Name 'Environment' -Value $c
        $appParam | Add-Member -type NoteProperty -Name 'Server' -Value $d
        $appParam | Add-Member -type NoteProperty -name 'Group' -value $e
        $appParam | Add-Member -type NoteProperty -name 'Remote' -value $f
        $output.Add($a,$appParam)
    }
}

ForEach($out in $output.keys){
    $a = $output.$out.Build
    $b = $output.$out.Environment
    $c = $output.$out.Server
    $d = $output.$out.Remote
    $deployParams.add($out,"(Set-DeploymentVariables -site `'$out`' -build `'$a`' -environment `'$b`' -server `'$c`')")
    $remoteParams.add($out,"(Set-DeploymentVariables -site `'$out`' -build `'$a`' -environment `'$d`')")
    $rcParams.add($out,"(Set-DeploymentVariables -site `'$out`' -build `'$a`' -environment `'RC1-US`')")
    }
#endregion buildScripts

#region buildGroups
$intranets = $output.GetEnumerator() | Where-Object {$_.Value.Group -eq "Intranets"}
$pricing = $output.GetEnumerator() | Where-Object {$_.Value.Group -eq "Pricing"}
$enterprise = $output.GetEnumerator() | Where-Object {$_.Value.Group -eq "Enterprise Customer"}
$services = $output.GetEnumerator() | Where-Object {$_.Value.Group -eq "Services"}
$UtilApps = $output.GetEnumerator() | Where-Object {$_.Value.Group -eq "Util Apps"}
$EOMS = $output.GetEnumerator() | Where-Object {$_.Value.Group -eq "EOMS"}
$Others = $output.GetEnumerator() | Where-Object {$_.Value.Group -eq "Other"}
#endregion buildGroups

#region localBuilds
For($i = 0; $i -lt $intranets.count; $i++){
    $a = $intranets[$i].Name
    $b = $intranets[$i].Value.Build
    $c = $deployParams.$a
    $iList += "$a - $b`n"
    If($i -eq $intranets.count -1){
        $c = $c + " | Join-DeploymentVariables | Push-Deployment"
    }
    Else{
    $c = $c + ","
    }
    $diList += "$c`n"
}

For($i = 0; $i -lt $pricing.count; $i++){
    $a = $pricing[$i].Name
    $b = $pricing[$i].Value.Build
    $c = $deployParams.$a
    $pList += "$a - $b`n"
    If($i -eq $pricing.count -1){
        $c = $c + " | Join-DeploymentVariables | Push-Deployment"
    }
    Else{
    $c = $c + ","
    }
    $dpList += "$c`n"
    }

For($i = 0; $i -lt $enterprise.count; $i++){
    $a = $enterprise[$i].Name
    $b = $enterprise[$i].Value.Build
    $c = $deployParams.$a
    $eList += "$a - $b`n"
    If($i -eq $enterprise.count -1){
        $c = $c + " | Join-DeploymentVariables | Push-Deployment"
    }
    Else{
    $c = $c + ","
    }
    $deList += "$c`n"
    }

For($i = 0; $i -lt $services.count; $i++){
    $a = $services[$i].Name
    $b = $services[$i].Value.Build
    $c = $deployParams.$a
    $sList += "$a - $b`n"
    If($i -eq $services.count -1){
        $c = $c + " | Join-DeploymentVariables | Push-Deployment"
    }
    Else{
    $c = $c + ","
    }
    $dsList += "$c`n"
    }

For($i = 0; $i -lt $utilApps.count; $i++){
    $a = $utilApps[$i].Name
    $b = $utilApps[$i].Value.Build
    $c = $deployParams.$a
    $uList += "$a - $b`n"
    If($i -eq $utilApps.count -1){
        $c = $c + " | Join-DeploymentVariables | Push-Deployment"
    }
    Else{
    $c = $c + ","
    }
    $duList += "$c`n"
    }

For($i = 0; $i -lt $EOMS.count; $i++){
    $a = $EOMS[$i].Name
    $b = $EOMS[$i].Value.Build
    $c = $deployParams.$a
    $eomsList += "$a - $b`n"
    If($i -eq $EOMS.count -1){
        $c = $c + " | Join-DeploymentVariables | Push-Deployment"
    }
    Else{
    $c = $c + ","
    }
    $deomsList += "$c`n"
    }

For($i = 0; $i -lt $others.count; $i++){
    $a = $others[$i].Name
    $b = $others[$i].Value.Build
    $c = $deployParams.$a
    $oList += "$a - $b`n"
    If($i -eq $others.count -1){
        $c = $c + " | Join-DeploymentVariables | Push-Deployment"
    }
    Else{
    $c = $c + ","
    }
    $doList += "$c`n"
    }
#endregion LocalBuilds

#region remoteBuilds
For($i = 0; $i -lt $intranets.count; $i++){
    $a = $intranets[$i].Name
    $b = $intranets[$i].Value.Build
    $c = $remoteParams.$a
    If($i -eq $intranets.count -1){
        $rList += "$c"
    }
    Else{
    $c = $c + ",`n"
    $rList += "$c"
    }
}

For($i = 0; $i -lt $pricing.count; $i++){
    $a = $pricing[$i].Name
    $b = $pricing[$i].Value.Build
    $c = $remoteParams.$a
    If($rList -and $i -eq 0){
    $rlist += ",`n`n"
    }
    If($rList){
    $c = ",`n" + $c + ",`n"
    $rList += "$c"
    }
    If($i -eq $pricing.count -1){
        $rList += "$c"
    }
    Else{
    $c = $c + ",`n`n"
    $rList += "$c"
    }
}

For($i = 0; $i -lt $enterprise.count; $i++){
    $a = $enterprise[$i].Name
    $b = $enterprise[$i].Value.Build
    $c = $remoteParams.$a
    If($rList -and $i -eq 0){
    $rlist += ",`n`n"
    }
    If($i -eq $enterprise.count -1){
        $rList += "$c"
    }
    Else{
    $c = $c + ",`n"
    $rList += "$c"
    }
}

For($i = 0; $i -lt $services.count; $i++){
    $a = $services[$i].Name
    $b = $services[$i].Value.Build
    $c = $remoteParams.$a
    If($rList -and $i -eq 0){
    $rlist += ",`n`n"
    }
    If($i -eq $services.count -1){
        $rList += "$c"
    }
    Else{
    $c = $c + ",`n"
    $rList += "$c"
    }
}

For($i = 0; $i -lt $utilApps.count; $i++){
    $a = $utilApps[$i].Name
    $b = $utilApps[$i].Value.Build
    $c = $remoteParams.$a
    If($rList -and $i -eq 0){
    $rlist += ",`n`n"
    }
    If($i -eq $utilApps.count -1){
        $rList += "$c"
    }
    Else{
    $c = $c + ",`n"
    $rList += "$c"
    }
}

For($i = 0; $i -lt $EOMS.count; $i++){
    $a = $EOMS[$i].Name
    $b = $EOMS[$i].Value.Build
    $c = $remoteParams.$a
    If($rList -and $i -eq 0){
    $rlist += ",`n`n"
    }
    If($i -eq $EOMS.count -1){
        $rList += "$c"
    }
    Else{
    $c = $c + ",`n"
    $rList += "$c"
    }
}

$rList += " | Join-DeploymentVariables | Push-Deployment -silent"
#endregion remoteBuilds

#region rcBuilds
For($i = 0; $i -lt $intranets.count; $i++){
    $a = $intranets[$i].Name
    $b = $intranets[$i].Value.Build
    $c = $rcParams.$a
    If($i -eq $intranets.count -1){
        $rcList += "$c"
    }
    Else{
    $c = $c + ",`n"
    $rcList += "$c"
    }
}

For($i = 0; $i -lt $pricing.count; $i++){
    $a = $pricing[$i].Name
    $b = $pricing[$i].Value.Build
    $c = $rcParams.$a
    If($rcList -and $i -eq 0){
    $rcList += ",`n`n"
    }
    If($rcList){
    $c = ",`n" + $c + ",`n"
    $rcList += "$c"
    }
    If($i -eq $pricing.count -1){
        $rcList += "$c"
    }
    Else{
    $c = $c + ",`n`n"
    $rcList += "$c"
    }
}

For($i = 0; $i -lt $enterprise.count; $i++){
    $a = $enterprise[$i].Name
    $b = $enterprise[$i].Value.Build
    $c = $rcParams.$a
    If($rcList -and $i -eq 0){
    $rcList += ",`n`n"
    }
    If($i -eq $enterprise.count -1){
        $rcList += "$c"
    }
    Else{
    $c = $c + ",`n"
    $rcList += "$c"
    }
}

For($i = 0; $i -lt $services.count; $i++){
    $a = $services[$i].Name
    $b = $services[$i].Value.Build
    $c = $rcParams.$a
    If($rcList -and $i -eq 0){
    $rcList += ",`n`n"
    }
    If($i -eq $services.count -1){
        $rcList += "$c"
    }
    Else{
    $c = $c + ",`n"
    $rcList += "$c"
    }
}

For($i = 0; $i -lt $utilApps.count; $i++){
    $a = $utilApps[$i].Name
    $b = $utilApps[$i].Value.Build
    $c = $rcParams.$a
    If($rcList -and $i -eq 0){
    $rcList += ",`n`n"
    }
    If($i -eq $utilApps.count -1){
        $rcList += "$c"
    }
    Else{
    $c = $c + ",`n"
    $rcList += "$c"
    }
}

For($i = 0; $i -lt $EOMS.count; $i++){
    $a = $EOMS[$i].Name
    $b = $EOMS[$i].Value.Build
    $c = $rcParams.$a
    If($rcList -and $i -eq 0){
    $rcList += ",`n`n"
    }
    If($i -eq $EOMS.count -1){
        $rcList += "$c"
    }
    Else{
    $c = $c + ",`n"
    $rcList += "$c"
    }
}

$rcList += " | Join-DeploymentVariables | Push-Deployment -silent"
#endregion rcBuilds

#region textOutput
$writeToScript = @"

#
# INTRANET DEPLOYMENT
# 
# $env:USERNAME << Deployer's name goes here
#

break

<# Builds you will be deploying

# Intranets
# ------------
$iList
# Pricing
# ------------
$pList
# EnterpriseCustomer
# ------------
$eList
# Services
# ------------
$sList
# Util Apps
# ------------
$uList
# EOMS
# ------------
$eomsList
# Other
# ------------
$oList
#>

# Intranets - US
# -----------
$diList
# Pricing - US
# --------
$dpList
# EnterpriseCustomer  - US
# ------------
$deList
# Services - US
#---------------
$dsList
# Util Apps - US
# -------
$duList
# EOMS - US
# ------------
$deomsList

##############
# DOA RC1-US # 
##############

$rcList

#############
# DOA UK/JP # 
#############

$rList


"@
#endregion textOutput

#region outputScript
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
$path = "\\storage\Development\NetAdmin\Documentation\Deployers\Deployments\IntranetDeployment-" + ($date.ToString('MM.dd.yyyy')) + ".ps1"
    Switch(Test-Path $path){
        $True{
            $ButtonType = [System.Windows.MessageBoxButton]::Ok
            $MessageboxTitle = “Error”
            $Messageboxbody = “Build Script already Exists”
            $MessageIcon = [System.Windows.MessageBoxImage]::Warning
            [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
            Break
        }
        $False{
            New-Item $path -type File -value $writeToScript
        }
    }
#endregion outputScript	

}