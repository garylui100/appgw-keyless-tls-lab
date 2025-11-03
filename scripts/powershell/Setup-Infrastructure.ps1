# Application Gateway - Managed HSM Keyless TLS Setup Script (PowerShell)
# This script automates the deployment of Azure resources for the keyless TLS lab

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-appgw-mhsm-lab",
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "East US 2",
    
    [Parameter(Mandatory = $false)]
    [string]$HSMName = "mhsm-keyless-tls-lab",
    
    [Parameter(Mandatory = $false)]
    [string]$AppGatewayName = "appgw-keyless-tls",
    
    [Parameter(Mandatory = $false)]
    [string]$VNetName = "vnet-appgw-mhsm",
    
    [Parameter(Mandatory = $false)]
    [string]$ServicePrincipalName = "sp-tls-offload"
)

# Import required modules
Import-Module Az.Accounts -Force
Import-Module Az.Resources -Force
Import-Module Az.Network -Force
Import-Module Az.KeyVault -Force

# Function to write colored output
function Write-ColoredOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colors = @{
        "Red" = [ConsoleColor]::Red
        "Green" = [ConsoleColor]::Green
        "Yellow" = [ConsoleColor]::Yellow
        "Blue" = [ConsoleColor]::Blue
        "White" = [ConsoleColor]::White
    }
    
    Write-Host $Message -ForegroundColor $colors[$Color]
}

function Write-Status {
    param([string]$Message)
    Write-ColoredOutput "[INFO] $Message" "Blue"
}

function Write-Success {
    param([string]$Message)
    Write-ColoredOutput "[SUCCESS] $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColoredOutput "[WARNING] $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColoredOutput "[ERROR] $Message" "Red"
}

# Function to check Azure PowerShell login
function Test-AzureLogin {
    Write-Status "Checking Azure PowerShell login status..."
    
    try {
        $context = Get-AzContext
        if ($null -eq $context) {
            Write-Error "You are not logged in to Azure PowerShell. Please run 'Connect-AzAccount' first."
            exit 1
        }
        Write-Success "Azure PowerShell login verified"
        Write-Status "Current subscription: $($context.Subscription.Name)"
    }
    catch {
        Write-Error "Error checking Azure context: $_"
        exit 1
    }
}

# Function to create resource group
function New-ResourceGroupDeployment {
    Write-Status "Creating resource group: $ResourceGroupName"
    
    try {
        $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
        Write-Success "Resource group created successfully"
        return $rg
    }
    catch {
        Write-Error "Failed to create resource group: $_"
        throw
    }
}

# Function to create virtual network
function New-VirtualNetworkDeployment {
    Write-Status "Creating virtual network: $VNetName"
    
    try {
        # Create subnets
        $appGwSubnet = New-AzVirtualNetworkSubnetConfig -Name "appgw-subnet" -AddressPrefix "10.0.1.0/24"
        $backendSubnet = New-AzVirtualNetworkSubnetConfig -Name "backend-subnet" -AddressPrefix "10.0.2.0/24"
        
        # Create VNet
        $vnet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $Location -Name $VNetName -AddressPrefix "10.0.0.0/16" -Subnet $appGwSubnet, $backendSubnet
        
        Write-Success "Virtual network created successfully"
        return $vnet
    }
    catch {
        Write-Error "Failed to create virtual network: $_"
        throw
    }
}

# Function to create public IP
function New-PublicIPDeployment {
    Write-Status "Creating public IP for Application Gateway"
    
    try {
        $pip = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $Location -Name "$AppGatewayName-pip" -AllocationMethod Static -Sku Standard
        Write-Success "Public IP created successfully"
        return $pip
    }
    catch {
        Write-Error "Failed to create public IP: $_"
        throw
    }
}

# Function to create Managed HSM
function New-ManagedHSMDeployment {
    Write-Status "Creating Managed HSM: $HSMName"
    Write-Warning "Managed HSM creation can take 15-20 minutes..."
    
    try {
        # Get current user object ID
        $context = Get-AzContext
        $currentUser = Get-AzADUser -SignedIn
        
        # Create Managed HSM
        $hsm = New-AzKeyVaultManagedHsm -ResourceGroupName $ResourceGroupName -Name $HSMName -Location $Location -Administrator $currentUser.Id
        
        Write-Success "Managed HSM created successfully"
        Write-Warning "Remember to activate the HSM and create the security domain"
        return $hsm
    }
    catch {
        Write-Error "Failed to create Managed HSM: $_"
        throw
    }
}

# Function to create service principal
function New-ServicePrincipalDeployment {
    Write-Status "Creating service principal: $ServicePrincipalName"
    
    try {
        # Create service principal
        $sp = New-AzADServicePrincipal -DisplayName $ServicePrincipalName
        
        # Get subscription scope
        $subscriptionId = (Get-AzContext).Subscription.Id
        $scope = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName"
        
        # Assign Contributor role
        New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Contributor" -Scope $scope
        
        Write-Success "Service principal created successfully"
        Write-Status "Application ID: $($sp.AppId)"
        
        # Create credentials object
        $credentials = @{
            AppId = $sp.AppId
            ObjectId = $sp.Id
            TenantId = (Get-AzContext).Tenant.Id
        }
        
        # Save credentials to file
        $credentials | ConvertTo-Json | Out-File -FilePath "service-principal-credentials.json" -Encoding UTF8
        Write-Success "Service principal credentials saved to service-principal-credentials.json"
        
        return $sp
    }
    catch {
        Write-Error "Failed to create service principal: $_"
        throw
    }
}

# Function to assign HSM permissions
function Set-HSMPermissions {
    param([object]$ServicePrincipal)
    
    Write-Status "Assigning Managed HSM permissions to service principal"
    
    try {
        # Wait for HSM to be ready
        Start-Sleep -Seconds 30
        
        # Assign Managed HSM Crypto User role
        New-AzKeyVaultRoleAssignment -HsmName $HSMName -RoleDefinitionName "Managed HSM Crypto User" -ObjectId $ServicePrincipal.Id -Scope "/keys"
        
        Write-Success "HSM permissions assigned successfully"
    }
    catch {
        Write-Error "Failed to assign HSM permissions: $_"
        throw
    }
}

# Function to create Application Gateway
function New-ApplicationGatewayDeployment {
    param([object]$VNet, [object]$PublicIP)
    
    Write-Status "Creating Application Gateway: $AppGatewayName"
    Write-Warning "This is a basic configuration. You'll need to configure TLS settings separately."
    
    try {
        # Get subnet
        $subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "appgw-subnet"
        
        # Create IP configuration
        $gipconfig = New-AzApplicationGatewayIPConfiguration -Name "gwconfig" -Subnet $subnet
        
        # Create frontend IP configuration
        $fipconfig = New-AzApplicationGatewayFrontendIPConfig -Name "fip01" -PublicIPAddress $PublicIP
        
        # Create frontend port
        $fp = New-AzApplicationGatewayFrontendPort -Name "port01" -Port 80
        
        # Create backend address pool
        $pool = New-AzApplicationGatewayBackendAddressPool -Name "pool01"
        
        # Create HTTP settings
        $poolSetting = New-AzApplicationGatewayBackendHttpSettings -Name "setting01" -Port 80 -Protocol Http -CookieBasedAffinity Disabled
        
        # Create HTTP listener
        $listener = New-AzApplicationGatewayHttpListener -Name "listener01" -Protocol Http -FrontendIPConfiguration $fipconfig -FrontendPort $fp
        
        # Create routing rule
        $rule = New-AzApplicationGatewayRequestRoutingRule -Name "rule01" -RuleType basic -BackendHttpSettings $poolSetting -HttpListener $listener -BackendAddressPool $pool
        
        # Create SKU
        $sku = New-AzApplicationGatewaySku -Name Standard_v2 -Tier Standard_v2 -Capacity 2
        
        # Create Application Gateway
        $appgw = New-AzApplicationGateway -Name $AppGatewayName -ResourceGroupName $ResourceGroupName -Location $Location -BackendAddressPools $pool -BackendHttpSettingsCollection $poolSetting -FrontendIpConfigurations $fipconfig -GatewayIpConfigurations $gipconfig -FrontendPorts $fp -HttpListeners $listener -RequestRoutingRules $rule -Sku $sku
        
        Write-Success "Application Gateway created successfully"
        return $appgw
    }
    catch {
        Write-Error "Failed to create Application Gateway: $_"
        throw
    }
}

# Function to display next steps
function Show-NextSteps {
    Write-Success "Infrastructure deployment completed!"
    Write-Host ""
    Write-Status "Next steps:"
    Write-Host "1. Activate your Managed HSM and create the security domain"
    Write-Host "2. Generate TLS keys in the Managed HSM using the TLS Offload Library"
    Write-Host "3. Configure Application Gateway with keyless TLS settings"
    Write-Host "4. Test the TLS configuration"
    Write-Host ""
    Write-Status "Resources created:"
    Write-Host "- Resource Group: $ResourceGroupName"
    Write-Host "- Managed HSM: $HSMName"
    Write-Host "- Application Gateway: $AppGatewayName"
    Write-Host "- Virtual Network: $VNetName"
    Write-Host "- Service Principal: $ServicePrincipalName"
    Write-Host ""
    Write-Warning "Important: Review and secure the service principal credentials in service-principal-credentials.json"
}

# Main execution function
function Start-LabSetup {
    Write-Status "Starting Application Gateway - Managed HSM Keyless TLS Lab Setup"
    
    try {
        Test-AzureLogin
        $rg = New-ResourceGroupDeployment
        $vnet = New-VirtualNetworkDeployment
        $pip = New-PublicIPDeployment
        $hsm = New-ManagedHSMDeployment
        $sp = New-ServicePrincipalDeployment
        Set-HSMPermissions -ServicePrincipal $sp
        $appgw = New-ApplicationGatewayDeployment -VNet $vnet -PublicIP $pip
        Show-NextSteps
        
        Write-Success "Setup completed successfully!"
    }
    catch {
        Write-Error "Setup failed: $_"
        throw
    }
}

# Run the setup
Start-LabSetup