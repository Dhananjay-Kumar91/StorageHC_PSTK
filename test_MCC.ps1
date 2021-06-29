######################################################################################################################
#'Enumerate Volumes.
######################################################################################################################

Function Get-VolumeStatus($cluster) {
    $volumeOffline = @()
    $volumeHighUtil = @()
    $volume_autogrow_disabled = @()
    $volume_snapdelete_enabled = @()
    Try {
     
        Process-cluster $cluster
        $Volumes = Get-Ncvol -ErrorAction Stop
        Write-Log -Info -Message "Enumerated volumes on cluster ""$cluster"""
    }
    Catch {
        Write-Log -Error -Message "Failed enumerating volumes on cluster ""$cluster"""
        [Int]$script:errorCount++
        Break;
    }
    $LUNVolumes = (Get-NcLun).Volume
    foreach ($volume in $Volumes) {
        If ($Volume.state -ne "online") {
         
            $volumeOffline += $Volume.name
        }
        if (($volume.VolumeSecurityAttributes.Style) -eq 'unix' -And !($Volume.Name.Contains("vol0")) -And !($Volume.Name.Contains("root")) -and !($volume.Vserver.Contains("-mc"))){
            echo "True"
            [Int]$percent_used = $Volume.used
            [String]$volume_type = $volume.VolumeIdAttributes.Type
            If ( $percent_used -gt 88 -And !($Volume.Name.Contains("vol0")) -And !($Volume.Name.Contains("root")) -and $volume_type -notcontains "dp" -and !($Volume.Name.Contains("MDV"))  ) {
                $volumeHighUtil += $Volume.name
            }

        }ElseIf (($volume.VolumeSecurityAttributes.Style) -eq 'ntfs' -And !($Volume.Name.Contains("vol0")) -And !($Volume.Name.Contains("root")) -and !($volume.Vserver.Contains("-mc"))){
            echo "False"
            [Int64]$quota_size = (Get-NcQuota -Volume $Volume).DiskLimit
            [Int64]$vol_used = $Volume.used
            [Int64]$volPercentUsed = [math]::round(($vol_used / $quota_size) * 100, 0)
            If ( $volPercentUsed -gt 88 -And !($Volume.Name.Contains("vol0")) -And !($Volume.Name.Contains("root")) -and $volume_type -notcontains "dp" -and !($Volume.Name.Contains("MDV"))  ) {
                $volumeHighUtil += $Volume.name
            }
            [String]$vol_autogrow_status = $Volume.VolumeAutosizeAttributes.IsEnabled
            If ($vol_autogrow_status -eq "False" -And !($Volume.Name.Contains("vol0")) -And !($Volume.Name.Contains("root")) -and $volume_type -notcontains "dp" -and !($Volume.Name.Contains("MDV"))) {
                $volume_autogrow_disabled += $Volume.Name
            }

        }
    
    } #checking vol online/offline

    return $volumeOffline, $volumeHighUtil, $volume_autogrow_disabled
}
Get-VolumeStatus($cluster)



######################################################################################################################
#'Enumerate Metrocluster status.
######################################################################################################################

Function get-metroclusterstatus($cluster){
    $comp_list =@()
    $result_list = @()
    $date_list = @()
    try{
        #Process-cluster $cluster
        $MCStatus = Get-NcMetroclusterCheck
    } catch{
        Write-Log -Error -Message "Failed enumerating Metrocluster Status on cluster ""$cluster"""
        [Int]$script:errorCount++
        Break;   
    }
    
    foreach ($comp in $MCStatus){
        $compn = $comp.Component
        $res = $comp.result
        $dt = $comp.TimestampDT
        if ($res -eq 'ok'){
            $comp_list += $compn
            $result_list += $res
            $date_list += $dt
        }
    }
    return $comp_list, $result_list, $date_list
}




######################################################################################################################
#'Enumerate Metrocluster  Link status.
######################################################################################################################

Function get-metroclusterlinkstatus($cluster){
    $inf_list =@()
    $inf_node = @()
    $linkstatus_list = @()
    try{
        #Process-cluster $cluster
        $MCinterconnect = Get-NcMetroclusterInterconnectAdapter
    } catch{
        Write-Log -Error -Message "Failed enumerating Metrocluster Status on cluster ""$cluster"""
        [Int]$script:errorCount++
        Break;   
    }
    
    foreach ($interface in $MCinterconnect){
        $adapter = $interface.AdapterName
        $interface_node = $interface.NodeName
        $interface_status = $interface.PhysicalLinkStatus
        if ($interface_status -eq 'UP'){
            $inf_list += $adapter
            $inf_node += $interface_node
            $linkstatus_list += $interface_status
        }
    }
    return $inf_list, $inf_node, $linkstatus_list
}


Function Metrocluster-Data($cluster){

    $cluster_name = Cluster-Name $cluster
    $comp_list, $result_list, $date_list = get-metroclusterstatus $cluster
    $comp_error_table = "<TR><TH>Component</TH><TH>Result</TH><TH>Checked On</TH></TR>"
    [int]$comp_error_count = $comp_list.count
    if ( $comp_error_count-eq 0){
        $metroclusterStatus = "<TD bgcolor=#33FFBB> Ok </TD>"
    }else{
        for ($i = 0; $i -lt $comp_error_count; $i++){
            $comp = $comp_list[$i]
            $res = $result_list[$i]
            $dt = $date_list[$i]
            $comp_error_table += "<TR><TD bgcolor=#FA8074>$comp</TD><TD bgcolor=#FA8074>$res</TD><TD bgcolor=#FA8074>$dt</TD></TR>"
        }
    $metroclusterStatus = @"
    <TD bgcolor=#FA8074>
        <button type="button" class="collapsible"> $comp_error_count Metro Cluster Component in Error </button>
        <div class="errorContent">
        <table>
        $comp_error_table
        </table>
        </div>
    </TD>
"@
    }

    $inf_list, $inf_node, $linkstatus_list = get-metroclusterlinkstatus $cluster
    $inf_down_table = "<TR><TH>Adapter</TH><TH>Node</TH><TH>Link Status</TH></TR>"
    [int]$interface_down_count = $inf_list.count
    if ( $interface_down_count-eq 0){
        $metroclusterlinkStatus = "<TD bgcolor=#33FFBB> Ok </TD>"
    }else{
        for ($i = 0; $i -lt $interface_down_count; $i++){
            $adapter = $inf_list[$i]
            $adapter_node = $inf_node[$i]
            $link = $linkstatus_list[$i]
            $inf_down_table += "<TR><TD bgcolor=#FA8074>$adapter</TD><TD bgcolor=#FA8074>$adapter_node</TD><TD bgcolor=#FA8074>$link</TD></TR>"
        }
    $metroclusterlinkStatus = @"
    <TD bgcolor=#FA8074>
        <button type="button" class="collapsible"> $comp_error_count Metro Cluster Interface Down </button>
        <div class="errorContent">
        <table>
        $inf_down_table
        </table>
        </div>
    </TD>
"@
    }
    $Metrocluster_report_data = @"
      <TR>
          <TD>$cluster_name</TD>
          $metroclusterStatus
          $metroclusterlinkStatus

      </TR>
"@
    return $Metrocluster_report_data
}