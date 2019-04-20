[CmdletBinding()]
Param(       
    [Parameter(Mandatory = $true)]               
    [String]$ResourceGroup,
    [Switch]$json
)

if($PSVersionTable.PSVersion -lt 5.0){
    return "PowerShell Version is too old. Please update to 5.0 and later"
    break
}

if(!(Get-Module -ListAvailable -Name "Az")){
    $AzInstalled = $false
    do{
        Write-Host "Az Module Not Present. Installing from Powershell Gallery...." -ForegroundColor Yellow
        Install-Module "Az" -Force
        $AzInstalled = $true
      }
    while($AzInstalled = $false)
}
else{
    Import-Module -Name Az
}


Get-AzResourceGroup -Name $ResourceGroup -ErrorVariable notPresent -ErrorAction SilentlyContinue

if ($notPresent) {
    Write-Host "Possible Incorrect Resource Group. See Below Error.`n" -ForegroundColor Red
    Write-Host $notPresent -ForegroundColor Yellow
}

else {

    $VMList = Get-AzVM -ResourceGroupName $ResourceGroup
    $NetworkResources = Get-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup
    $PublicIps = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroup | select Name, IpAddress

    $VMs = foreach ($VM in $VMList) {

        $NetIp = ($NetworkResources | Where-Object { $_.Parameters.virtualMachineName.Value -eq $VM.Name } | Select-Object -First 1).Parameters.publicIpAddressName.Value
        $NSG = ($NetworkResources | Where-Object { $_.Parameters.virtualMachineName.Value -eq $VM.Name } | Select-Object -First 1).Parameters.networkSecurityGroupId.Value
        $Image = $VM.StorageProfile.ImageReference.Id

        [PSCustomObject]@{

            VMName        = $VM.Name
            Region        = $VM.Location
            VmSize        = $VM.HardwareProfile.VmSize
            VmHostName    = $VM.OSProfile.ComputerName
            ResourceGroup = $VM.ResourceGroupName
            Image         = $(if ($Image) { $Image.Substring($Image.LastIndexOf('/') + 1) })
            Status        = if ($VM.StatusCode -eq 'OK') { 'UP' }
            DeployState   = $VM.ProvisioningState
            PublicIP      = ($publicIps | Where-Object { $_.Name -eq $NetIp }).IpAddress
            NSG           = $(if ($NSG) { $NSG.Substring($NSG.LastIndexOf('/') + 1) })
        }    
    }

    if ($json) { $VMs | Sort-Object -Descending | ConvertTo-Json -Depth 4 }

    else { $VMs | Sort-Object -Descending | Format-Table } 

}
