$ResourceGroup = Read-Host "Please Enter Resource Group" 

$VMList = Get-AzVM -ResourceGroupName $ResourceGroup
$NetworkResources = Get-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup
$PublicIps = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroup | select Name, IpAddress

$VMs = foreach ($VM in $VMList) {

    $NetIp = ($NetworkResources | Where-Object {$_.Parameters.virtualMachineName.Value -eq $VM.Name} | Select-Object -First 1).Parameters.publicIpAddressName.Value
    $NSG = ($NetworkResources | Where-Object {$_.Parameters.virtualMachineName.Value -eq $VM.Name} | Select-Object -First 1).Parameters.networkSecurityGroupId.Value
    $Image = $VM.StorageProfile.ImageReference.Id

    [PSCustomObject]@{

        VMName        = $VM.Name
        Region        = $VM.Location
        VmSize        = $VM.HardwareProfile.VmSize
        VmHostName    = $VM.OSProfile.ComputerName
        ResourceGroup = $VM.ResourceGroupName
        Image         = $(if ($Image) {$Image.Substring($Image.LastIndexOf('/') + 1)})
        Status        = $VM.StatusCode
        DeployState   = $VM.ProvisioningState
        PublicIP      = ($publicIps | Where-Object{$_.Name -eq $NetIp}).IpAddress
        NSG           = $(if ($NSG) {$NSG.Substring($NSG.LastIndexOf('/') + 1)})
    }    
}

$VMs | Sort-Object -Descending | Format-Table
