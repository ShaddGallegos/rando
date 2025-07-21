# Define variables
$WSL_Interface = "vEthernet (WSL (Hyper-V firewall))"
$TARGET_IP = "172.17.93.214"
$GATEWAY_IP = "192.168.1.1"

Write-Host "Checking Network Configuration..."
Get-NetIPAddress | Format-Table

Write-Host "Testing Connectivity to Target..."
$testConnection = Test-NetConnection -ComputerName $TARGET_IP -Port 22
if ($testConnection.TcpTestSucceeded) {
    Write-Host "TCP connectivity to $TARGET_IP is successful."
} else {
    Write-Host "TCP test failed!"
}

Write-Host "Checking Existing NAT Configuration..."
$ExistingNat = Get-NetNat | Where-Object { $_.Name -eq "WSL-NAT" }
if ($ExistingNat) {
    Write-Host "Existing NAT detected. Removing conflicting configuration..."
    Remove-NetNat -Name "WSL-NAT"
    Start-Sleep -Seconds 5  # Wait briefly before retrying
} else {
    Write-Host "No existing NAT configuration found."
}

Write-Host "Creating New NAT Configuration..."
try {
    New-NetNat -Name "WSL-NAT" -InternalIPInterfaceAddressPrefix "172.23.144.0/20"
    Write-Host "New NAT configuration successfully created."
} catch {
    Write-Host "Error creating NAT: $_"
}

Write-Host "Verifying NAT configuration..."
Get-NetNat | Format-Table Name, InternalIPInterfaceAddressPrefix

Write-Host "Checking Available Network Interfaces..."
Get-NetIPInterface | Format-Table InterfaceAlias, Forwarding

Write-Host "Enabling IP Forwarding..."
$InterfaceExists = Get-NetIPInterface | Where-Object { $_.InterfaceAlias -eq $WSL_Interface }
if ($InterfaceExists) {
    try {
        Set-NetIPInterface -InterfaceAlias $WSL_Interface -Forwarding Enabled
        Write-Host "Enabled forwarding on $WSL_Interface."
    } catch {
        Write-Host "Failed to enable forwarding on $WSL_Interface. Error: $_"
    }
} else {
    Write-Host "Interface $WSL_Interface not found. Checking for alternate interfaces..."
    Get-NetIPInterface | Format-Table InterfaceAlias, Forwarding
}

Write-Host "Checking Windows Firewall Status..."
Get-Service -Name MpsSvc | Format-Table Name, Status

Write-Host "Enabling Firewall Services..."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

Write-Host "Flushing DNS Cache..."
ipconfig /flushdns

Write-Host "All checks and fixes complete!"