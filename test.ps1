$cluster = "192.168.0.101"
$credential = Get-NcCredential -Controller $cluster -ErrorAction Stop
Connect-NcController -Name $cluster -HTTPS -Credential $credential.Credential -ErrorAction Stop | Out-Null

Function Cluster-Name($cluster){
    try{
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

Cluster-Name $cluster