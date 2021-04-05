whoami

 

######################################################################################################################

#'Start a timer for logging.

######################################################################################################################

 

$elapsedTime = [System.Diagnostics.Stopwatch]::StartNew()

 

######################################################################################################################

#'Function to Get-IsoDateTime.

######################################################################################################################

 

Function Get-IsoDateTime{

  Return (Get-IsoDate) + " " + (Get-IsoTime)

}

 

######################################################################################################################

#'Function to Get-IsoDate.

######################################################################################################################

 

Function Get-IsoDate{

  Return Get-Date -uformat "%Y-%m-%d"

}

 

######################################################################################################################

#'Function to Get-IsoTime.

######################################################################################################################

 

Function Get-IsoTime{

  Return Get-Date -Format HH:mm:ss

}

 

######################################################################################################################

#'Initialization Section. Define Global Variables.

######################################################################################################################

 

[String]$script:scriptPath     = Split-Path($MyInvocation.MyCommand.Path)

[String]$script:scriptSpec     = $MyInvocation.MyCommand.Definition

[String]$script:scriptBaseName = (Get-Item $scriptSpec).BaseName

[String]$script:scriptName     = (Get-Item $scriptSpec).Name

[String]$script:scriptLogPath  = $($scriptPath + "\" + (Get-IsoDate))

[Int]$script:errorCount = 0

$ErrorActionPreference  = "Stop"

[String]$outfile = "C:\NA-Scripts\storage_report_output\"+(Get-IsoDate)+"_StorageHC.htm"

#$outfile = "C:\NA-Scripts\storage_report_output\test.html"



######################################################################################################################

#'Ensure that dates are always returned in English

######################################################################################################################

 

[System.Threading.Thread]::CurrentThread.CurrentCulture="en-US"

 

######################################################################################################################

#'Function to Write-Log

######################################################################################################################

 

Function Write-Log{

  Param(

     [Switch]$Info,

     [Switch]$Error,

     [Switch]$Debug,

     [Switch]$Warning,

     [String]$Message

  )

  #'---------------------------------------------------------------------------

  #'Add an entry to the log file and disply the output. Format: [Date],[TYPE],MESSAGE

  #'---------------------------------------------------------------------------

  [String]$lineNumber = $MyInvocation.ScriptLineNumber

  [Bool]$debugLogging = $False;

  If($Debug -And (-Not($debugLogging))){

     Return $Null;

  }

  Try{

     If($Error){

        If([String]::IsNullOrEmpty($_.Exception.Message)){

           [String]$line = $("`[" + (Get-IsoDateTime) + "`],`[ERROR`],`[LINE $lineNumber`]," + $Message)

        }Else{

           [String]$line = $("`[" + (Get-IsoDateTime) + "`],`[ERROR`],`[LINE $lineNumber`]," + $Message + ". Error """ + $_.Exception.Message + """")

        }

     }ElseIf($Info){

        [String]$line = $("`[" + (Get-IsoDateTime) + "`],`[INFO`]," + $Message)

     }ElseIf($Debug){

        [String]$line = $("`[" + $(Get-IsoDateTime) + "`],`[DEBUG`],`[LINE $lineNumber`]," + $Message)

     }ElseIf($Warning){

        [String]$line = $("`[" + (Get-IsoDateTime) + "`],`[WARNING`],`[LINE $lineNumber`]," + $Message)

     }Else{

        [String]$line = $("`[" + (Get-IsoDateTime) + "`],`[INFO`]," + $Message)

     }

     #'------------------------------------------------------------------------

     #'Display the console output.

     #'------------------------------------------------------------------------

     If($Error){

        If([String]::IsNullOrEmpty($_.Exception.Message)){

           Write-Host $($line + ". Error " + $_.Exception.Message) -Foregroundcolor Red

        }Else{

           Write-Host $line -Foregroundcolor Red

        }

     }ElseIf($Warning){

        Write-Host $line -Foregroundcolor Yellow

     }ElseIf($Debug -And $debugLogging){

        Write-Host $line -Foregroundcolor Magenta

     }Else{

        Write-Host $line -Foregroundcolor White

     }

     #'------------------------------------------------------------------------

     #'Append to the log. Omit debug loggging if not enabled.

     #'------------------------------------------------------------------------

     If($Debug -And $debugLogging){

        Add-Content -Path "$scriptLogPath.log" -Value $line -Encoding UTF8 -ErrorAction Stop

     }Else{

        Add-Content -Path "$scriptLogPath.log" -Value $line -Encoding UTF8 -ErrorAction Stop

     }

     If($Error){

        Add-Content -Path "$scriptLogPath.err" -Value $line -Encoding UTF8 -ErrorAction Stop

     }

     }Catch{

     Write-Warning "Could not write entry to output log file ""$scriptLogPath.log"". Log Entry ""$Message"""

  }

}


######################################################################################################################

#'Import the PSTK.

######################################################################################################################

 
Function Modules(){

   [String]$moduleName = "DataONTAP"

   Try{

       Import-Module DataONTAP -ErrorAction Stop | Out-Null

       Import-Module posh-ssh -ErrorAction Stop | Out-Null

       Get-Module -All | Out-Null

       Write-Log -Info -Message "Imported Module ""$moduleName"""

   }Catch{

       Write-Log -Error -Message "Failed importing module ""$moduleName"""

       Exit -1

   }

}


######################################################################################################################

# FUnction to create the HTML Body

######################################################################################################################

Function HTML-Body($current_time, $current_date){
    $css_fileSpec = "C:\NA-Scripts\css_template.txt"
    [String]$css = Get-Content -Path $css_fileSpec
    $clusters = Read-Cluster
    $storage_body = Cluster-ReportTable $clusters
    $html_body = 
    @"
    <!DOCTYPE html>
    <html lang="en">

    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Storage Health-Check</title>
    </head>
    $css
    <body>
        <h1> <strong> Motability - Storage Health Check Report - $current_time </strong></h1>
        <H4 style='color : #4CAF50;padding-left: 30px;'><strong> Date - $current_date </strong></H4>
        <H5 style='color : #464A46;font-size : 14px;padding-left: 30px;'><strong> Note : This report is for past 24hrs </strong></H5>
        <H4 style='color : #464A46;font-size : 21px;padding-left: 30px;'>Legend </H4>
        <table style='width:auto;padding-left: 30px; background-color: #efefef;word-break: keep-all;'>
            <tr>
                <td bgcolor=#FA8074>Red</td>
                <td style='background-color: white;'>Critical</td>
                <td bgcolor=#EFF613>Yellow</td>
                <td style='background-color: white;'>Warnings</td>
                <td bgcolor=#33FFBB>Green</td>
                <td style='background-color: white;'>OK</td>
            </tr>

        </table>
        <table></table>
<div class="tabs">

<input type="radio" id="tab1" name="tab-control" checked>
            <ul>
                <li title="Storage">
                    <label for="tab1" role="button">
                            <img
                                width="17"
                                hight="17"
                                src="https://image.flaticon.com/icons/svg/873/873135.svg"/><br /><span> Storage </span></label>
                    </li>
                </ul>

                <div class="slider">
                    <div class="indicator"></div>
                </div>
                <div class="content">
                    <section>
                        <h2>Storage</h2>
                            $storage_body
                    </section>
                </div>
            </div>
        </body>
    </html>
"@

    return $html_body
}

######################################################################################################################

#'Read the list of clusters.

######################################################################################################################

 

Function Read-Cluster(){
    $clusters = @()
    $Clusters_InputPath = "C:\NA-Scripts\cluster_input.txt"
   If(-Not(Test-Path -Path $Clusters_InputPath)){

       Write-Log -Warning -Message "The file ""$Clusters_InputPath"" does not exist"

       Exit -1

   }

   Try{

       $cluster_Input = Get-Content -Path $Clusters_InputPath -ErrorAction Stop

       Write-Log -Info -Message "Read file ""$Clusters_InputPath"""

   }Catch{

       Write-Log -Error -Message "Failed reading file ""$Clusters_InputPath"""

       Exit -1

   }
   foreach ($cluster in $cluster_Input){
    if ($cluster -ne ""){
        $clusters += $Cluster
        }
    }
   return $clusters

}


######################################################################################################################

#'Fetch Cluster Name

######################################################################################################################

Function Cluster-Name($cluster){
    try{
        Process-clusters $cluster
        $cluster_name = (Get-NcCluster).ClusterName
        Write-Log -Info -Message "Fetching Cluster Name"
    }catch{
        Write-Log -Error -Message "Failed to Fetch Cluster Name"
        $cluster_name = "NA"
        [Int]$script:errorCount++
        
        break;
    }
    return $cluster_name
}



######################################################################################################################

#'Connect to Cluster

######################################################################################################################

Function Process-cluster($cluster){
    try{
        $credential = Get-NcCredential -Controller $cluster -ErrorAction Stop
        Write-Log -Info -Message "Enumerated cached credentials for cluster ""$cluster"""
    }catch{
    Write-Log -Error -Message "Failed enumerating cached credentials for cluster ""$cluster"""
    [Int]$script:errorCount++
    Break;
    }
    try{
    Connect-NcController -Name $cluster -HTTPS -Credential $credential.Credential -ErrorAction Stop | Out-Null
    
    Write-Log -Info -Message $("Connected to cluster ""$cluster"" as user """ + $credential.Credential.UserName + """")

    }catch{

    Write-Log -Error -Message $("Connected to cluster ""$cluster"" as user """ + $credential.Credential.UserName + """")
    
    [Int]$script:errorCount++
    
    Break;
    }
}

######################################################################################################################

#'Get Nodes.

######################################################################################################################


Function Get-ClusterNodes($cluster){

   Try{
        Process-clusters $cluster

        $nodes = Get-NcNode -ErrorAction Stop

        Write-Log -Info -Message "Enumerated Nodes on cluster ""$cluster"""

     }Catch{

        Write-Log -Error -Message "Failed enumerating nodes on cluster ""$cluster"""
        $node = "NA"

        [Int]$script:errorCount++

        Break;

     }
    return $nodes
}

######################################################################################################################

#'Get Node Image Version.

######################################################################################################################


Function Get-Clusterimage($cluster){

   Try{
        Process-clusters $cluster

        $ClusterImage = (Get-NcClusterImage).CurrentVersion | Get-Unique -ErrorAction Stop

        Write-Log -Info -Message "Enumerated Cluster Version on cluster ""$cluster"""

     }Catch{

        Write-Log -Error -Message "Failed enumerating Cluster Version on cluster ""$cluster"""
        $node = "NA"

        [Int]$script:errorCount++

        Break;

     }
    return $ClusterImage
}


######################################################################################################################

#'Get Envirnment Status.

######################################################################################################################

Function Get-EnvStatus($cluster){

  $Command = "system health subsystem show -health !ok -fields subsystem"

  $credential = Get-NcCredential -Controller $cluster -ErrorAction Stop

  $SessionID = New-SSHSession -ComputerName $cluster -Credential $credential.Credential


  Try{

       $output = Invoke-SSHCommand -Index $sessionid.sessionid -Command $Command -ErrorAction Stop  # Invoke Command Over SSH

       Write-Log -Info -Message $("Executed command`: """ + $([String]::Join(" ", $command)) + """ on cluster ""$cluster""")

    }Catch{

       Write-Log -Error -Message $("Failed executing command`: """ + $([String]::Join(" ", $command)) + """ on cluster ""$cluster""")

       [Int]$script:errorCount++

       Break;

    }

    $output = $output.output
    return $output
}

######################################################################################################################

#'Get Chassis Status.

######################################################################################################################


Function Get-ChassisStatus($cluster){

  $Command = "system chassis fru show -status !ok -fields fru-name "

  $credential = Get-NcCredential -Controller $cluster -ErrorAction Stop

  $SessionID = New-SSHSession -ComputerName $cluster -Credential $credential.Credential


  Try{

       $output = Invoke-SSHCommand -Index $sessionid.sessionid -Command $Command -ErrorAction Stop  # Invoke Command Over SSH

       Write-Log -Info -Message $("Executed command`: """ + $([String]::Join(" ", $command)) + """ on cluster ""$cluster""")

    }Catch{

       Write-Log -Error -Message $("Failed executing command`: """ + $([String]::Join(" ", $command)) + """ on cluster ""$cluster""")

       [Int]$script:errorCount++

       Break;

    }

    $output = $output.output
    return $output
}

######################################################################################################################

#'Get Failed Disks.

######################################################################################################################



Function Failed-Disk($cluster){

     Try{
        Process-clusters $cluster

        $failedDisks = Get-NcDisk -ErrorAction Stop | Where-Object {$_.DiskRaidInfo.ContainerType -eq "broken"}


        Write-Log -Info -Message "Enumerated Disks on cluster ""$cluster"""

     }Catch{

        Write-Log -Error -Message "Failed enumerating disks on cluster ""$cluster"""

        [Int]$script:errorCount++

        Break;

     }
    return $failedDisks
}

######################################################################################################################

#'Enumerate the cluster health.

######################################################################################################################

 

Function Cluster-Health($cluster){

    $Command = "cluster show -health false "

    $credential = Get-NcCredential -Controller $cluster -ErrorAction Stop

    $SessionID = New-SSHSession -ComputerName $cluster -Credential $credential.Credential #Connect Over SSH

    Try{

       $output = Invoke-SSHCommand -Index $sessionid.sessionid -Command $Command # Invoke Command Over SSH

       Write-Log -Info -Message $("Executed Command`: """ + $([String]::Join(" ", $command)) + """ on cluster ""$cluster""")

    }Catch{

       Write-Log -Error -Message $("Failed Executing Command`: """ + $([String]::Join(" ", $command)) + """ on cluster ""$cluster""")

       [Int]$script:errorCount++

       Break;

    }
    $output = $output.output
    return $output

}

 

######################################################################################################################

#'Enumerate Spare Disks.

######################################################################################################################

 

Function Spare-Disk($cluster){


     $count = @()

     $nodeList = @()

     $spareList = @()

     [Int]$nodeSpareCount = 0

     $node = (Get-ClusterNodes($cluster))
     $nodeCount = $node.count

     Try{
        
        Process-clusters $cluster

        $spareDisks = Get-NcAggrspare -ErrorAction Stop # getting aggregate spare disks

        Write-Log -Info -Message "Enumerated spare disks on cluster ""$cluster"""

     }Catch{

        Write-Log -Error -Message "Failed enumerating spare disks on cluster ""$cluster"""

        [Int]$script:errorCount++

        Break;

     }

     $spareDiskCount  = $spareDisks.count

     $spareDiskOwner = $spareDisks.originalowner

     $script:sd = $null #'checking count of spare disks

     For($i=0;$i -lt $nodeCount;$i++){

        For($j=0;$j -le $spareDiskCount;$j++){

           If($nodeCount -lt 2){

               If($node.node -Match $spareDiskOwner[$j]){

                   $nodeSpareCount=$nodeSpareCount+1          

           }

        }else{

           If($node.node[$i] -Match $spareDiskOwner[$j]){

              $nodeSpareCount=$nodeSpareCount+1

                }

            }

        }

        $nodeSpareCount = $nodeSpareCount - 1

        $count += "$nodeSpareCount"

        $nodeSpareCount = 0

        #$count

     }

     For($i=0;$i -lt $nodeCount;$i++){

        If($nodeCount -lt 2){

           $nodeList += $node.Node

            $spareList += $count[$i]

       }else{

           $nodeList += $node.Node[$i]

           $spareList += $count[$i]        

       }

        

     }
    return $nodeList, $spareList

}

 

######################################################################################################################

#'Enumerate Aggregates.

######################################################################################################################

 

Function aggregate-status($cluster){
    
  $aggregateOffline = @()
  $aggregateHighUtil = @()

  Try{
     
     Process-clusters $cluster

     $aggregates = Get-NcAggr -ErrorAction Stop

     Write-Log -Info -Message "Enumerated Aggregates on cluster ""$cluster"""

  }Catch{

     Write-Log -Error -Message "Failed enumerating aggregates on cluster ""$cluster"""

     [Int]$script:errorCount++

     Break;

  }


  ForEach($aggregate In $aggregates){

     If($aggregate.state -ne "online"){
        
        $aggregateOffline += $aggregate.name

     }

  }
   # checking aggr online/offline

  ForEach($aggregate In $aggregates){

     If($aggregate.used -gt 90 -And !($aggregate.Name.Contains("aggr0_"))){

        $aggregateHighUtil += $aggregate.name

     }

  }
    return $aggregateOffline, $aggregateHighUtil
}
 
######################################################################################################################

#'Enumerate Volumes.

######################################################################################################################

 

Function Get-VolumeStatus($cluster){
    
    $volumeOffline = @()
    $volumeHighUtil = @()

   Try{
        
        Process-clusters $cluster

        $Volumes = Get-Ncvol -ErrorAction Stop

        Write-Log -Info -Message "Enumerated volumes on cluster ""$cluster"""

     }Catch{

        Write-Log -Error -Message "Failed enumerating volumes on cluster ""$cluster"""

        [Int]$script:errorCount++

        Break;

     }
     foreach($volume in $Volumes){

        If($Volume.state -ne "online"){
            
            $volumeOffline += $Volume.name
        }
     } #checking vol online/offline

     foreach($volume in $Volumes){

        If($Volume.used -gt 96 -And !($Volume.Name.Contains("vol0"))){

            $volumeHighUtil += $Volume.name

        }

     }
     return $volumeOffline, $volumeHighUtil
}


######################################################################################################################

#'Enumerate Ethernet Ports.

######################################################################################################################

 

Function port-status($cluster){
    
     $portDown = @()

     $portDownNodes = @()

     Try{
        Process-clusters $cluster
        $ports = Get-NcNetPort -ErrorAction Stop

        Write-Log -Info -Message "Enumerated Ports for cluster ""$cluster"""

     }Catch{

        Write-Log -Error -Message "Failed enumerating ports for cluster ""$cluster"""

        [Int]$script:errorCount++

        Break;

     }
     $portExceptionPath = "C:\NA-Scripts\port_exception.txt"
     If(-Not(Test-Path -Path $portExceptionPath)){

        Write-Log -Error -Message "The File ""$portExceptionPath"" does not exist"

        [Int]$script:errorCount++

        Break;

     }

     Try{

        $portException = Get-Content -Path $portExceptionPath -ErrorAction Stop

        Write-Log -Info -Message "Read file ""$portExceptionPath"""

     }Catch{

        Write-Log -Error -Message "Failed reading file ""$portExceptionPath"""

        [Int]$script:errorCount++

        Break;

     }
     foreach($port in $ports){
        if ($port.LinkStatus -eq "up"){
            
            $portName = $port.Port

            $portNode = $port.Node

            $exceptionCheck = "$portName is down In $portNode"

            if ($exceptionCheck -notin $portException){

                $portDown += $portName
                $portDownNodes += $portNode
            }
        }
     }
     return $portDown, $portDownNodes
}

 

######################################################################################################################

#'Enumerate LUNs.

######################################################################################################################

 

Function LUNs-Status($cluster){

    $lunOffline = @()
    $lunHighUtil = @()

     Try{
        
        Process-clusters $cluster

        $luns = Get-NcLun -ErrorAction Stop

        Write-Log -Info -Message "Enumerated LUNs on cluster ""$cluster"""

     }Catch{

        Write-Log -Error -Message "Failed enumerating LUNs on cluster ""$cluster"""

        [Int]$script:errorCount++

        Break;

     }

     ForEach($lun In $luns){

        if($lun.state -ne "online"){

           $lunOffline += $lun.path

        }

     }
     ForEach($lun In $luns){
        
        $lunSize = [Long]($lun.Size)
        $lunUsed = [Long]($lun.SizeUsed)
        $lunPercentUsed = [Long]($lunUsed/$lunSize)*100
        if ($lunPercentUsed -gt 96){
            $lunHighUtil += $lun.path
        }

     }
     return $lunOffline, $lunHighUtil
}

 

######################################################################################################################

#'Enumerate network interfaces.

######################################################################################################################

 

Function Interface-Status($cluster){

   $InterfaceDown = @()

   Try{

        Process-clusters $cluster

        $Interfaces = Get-NcNetInterface -ErrorAction Stop

        Write-Log -Info -Message "Enumerated Network interfaces on cluster ""$cluster"""

     }Catch{

        Write-Log -Error -Message "Failed enumerating Network Interfaces on cluster ""$Cluster"""

        [Int]$script:errorCount++

        Break;

     }

     ForEach($Interface in $Interfaces){

        
        If(($Interface.OpStatus) -eq "down"){ # checking if opstatus is down

           $InterfaceDown += $Interface.InterfaceName

        }

     }
    return $InterfaceDown

}


######################################################################################################################

#'Enumerate SnapMirror lag Times.

######################################################################################################################

 

Function Snapmirror-Status($cluster){


     $snapmirrorHighLag = @()

     $snapmirrorUnhealthy = @()

     [int]$LagTimeSeconds = 86400 #24 urs In seconds

     Try{
        
        Process-clusters $cluster

        $snapmirrors = Get-NcSnapmirror -ErrorAction Stop

        Write-Log -Info -Message "Enumerated SnapMirror State and  Lag times on cluster ""$cluster"""

     }Catch{

        Write-Log -Error -Message "Failed enumerating SnapMirror State and Lag times on cluster ""$cluster"""

        [Int]$script:errorCount++

        Break;

     }

     foreach ($snapmirror in $snapmirrors){
        
        if ($snapmirror.state -ne "Snapmirrored"){
            
            $snapmirrorUnhealthy += $snapmirror.SourceLocation
        }
    }

     foreach ($snapmirror in $snapmirrors){

        [int]$snapmirrorLag = ($snapmirror.LagTime)
        
        if ($snapmirrorLag -gt $LagTimeSeconds){
            
            $snapmirrorHighLag += $snapmirror.SourceLocation
        }
    }
    return $snapmirrorUnhealthy, $snapmirrorHighLag
}


######################################################################################################################

#'Enumerate Cluster table data

######################################################################################################################

 

######################################################################################################################

#'Enumerate Cluster tables

######################################################################################################################

 Function Ontap-Data1($cluster){
    
    $noErrorMsg = "There are no entries matching your query."
    $cluster_name = Cluster-Name $cluster
    $cluster_version = Get-Clusterimage $cluster
    $subsystem_status = Get-EnvStatus $cluster
    $subsystem_status = $subsystem_status[0]
    if ($subsystem_status -eq $noErrorMsg){
        echo "No Error"
    }else{
        echo "Error"
    }
    
    $cluster_report_data = @"
        <TR>
            <TD>$cluster_name</TD>
            <TD>$cluster_version</TD>
            {hw_status}
            {cluster_status}
            {aggr_status}
            {spare_disks_status}
            {vol_status}
            {port_status}
            {lif_status}
            {snapmirror_status}
        </TR>
"@
    return $cluster_report_data
 }

Function Cluster-ReportTable($clusters){
    
    foreach($cluster in $clusters){

        [String]$ontap_data_1_dt += Ontap-Data1 $cluster

        [String]$ontap_data_2_dt += $cluster
    }   
    $cluster_report_body = @"
    <div>
    <h3 style='color : #464A46; font-size : 21px' align="" left ""> Ontap  - Part1 </h3>
    </caption>
        <Table>
            <TR>
                <TH><B> Cluster Name </B></TH>
                <TH><B> ONTAP version </B></TH>
                <TH><B> Hardware Status </B></TH>
                <TH><B> Cluster Status </B></TH>
                <TH><B> Aggr status </B></TH>
                <TH><B> Spare Disk Status </B></TH>
                <TH><B> Vol Status </B></TH>
                <TH><B> Port Status </B></TH>
                <TH><B> LIF status </B></TH>
                <TH><B> Snapmirror Status </B></TH>
            </TR>
            $ontap_data_1_dt
        </Table>
    <h3 style='color : #464A46; font-size : 21px' align="" left ""> Ontap  - Part2 </h3>
    </caption>
        <Table>
            <TR>
                <TH><B> Cluster Name </B></TH>
                <TH><B> Ifgrp Status </B></TH>
                <TH><B> CIFS/NFS/iSCSI </B></TH>
                <TH><B> LUN Status </B></TH>
                <TH><B> ACP Status </B></TH>
                <TH><B> SP Status </B></TH>
                <TH><B> Licenses / Certificates </B></TH>
                <TH><B> Cluster Config Bkp </B></TH>
            </TR>
            $ontap_data_2_dt
        </Table>
    </div>
"@
    return $cluster_report_body
}
$current_time = ""
$current_time = Get-IsoDateTime

$current_date = ""
$current_date = Get-IsoDate
$htmlOut = HTML-Body $current_time $current_date

Set-Content -Path $outfile -Value $htmlOut

#$cluster = "192.168.0.101"
#Interface-Status $cluster
#$nodeList, $spareList = (Snapmirror-Status $cluster)
#echo $nodeList, $spareList
#if ($fd -eq $null){
#    echo 'True'
#}
#else{
#    echo 'False'
#}
