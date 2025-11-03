#!/bin/bash

# Application Gateway - Managed HSM Keyless TLS Setup Script
# This script automates the deployment of Azure resources for the keyless TLS lab

set -e

# Configuration Variables
RESOURCE_GROUP_NAME="rg-appgw-mhsm-lab"
LOCATION="East US 2"
HSM_NAME="mhsm-keyless-tls-lab"
APP_GATEWAY_NAME="appgw-keyless-tls"
VNET_NAME="vnet-appgw-mhsm"
SERVICE_PRINCIPAL_NAME="sp-tls-offload"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Azure CLI is logged in
check_azure_login() {
    print_status "Checking Azure CLI login status..."
    if ! az account show &>/dev/null; then
        print_error "You are not logged in to Azure CLI. Please run 'az login' first."
        exit 1
    fi
    print_success "Azure CLI login verified"
}

# Function to create resource group
create_resource_group() {
    print_status "Creating resource group: $RESOURCE_GROUP_NAME"
    az group create \
        --name "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --output table
    print_success "Resource group created successfully"
}

# Function to create virtual network
create_virtual_network() {
    print_status "Creating virtual network: $VNET_NAME"
    
    # Create VNet
    az network vnet create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$VNET_NAME" \
        --address-prefix 10.0.0.0/16 \
        --subnet-name appgw-subnet \
        --subnet-prefix 10.0.1.0/24 \
        --output table

    # Create additional subnet for backend resources
    az network vnet subnet create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --vnet-name "$VNET_NAME" \
        --name backend-subnet \
        --address-prefix 10.0.2.0/24 \
        --output table

    print_success "Virtual network created successfully"
}

# Function to create public IP for Application Gateway
create_public_ip() {
    print_status "Creating public IP for Application Gateway"
    az network public-ip create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "${APP_GATEWAY_NAME}-pip" \
        --allocation-method Static \
        --sku Standard \
        --output table
    print_success "Public IP created successfully"
}

# Function to create Managed HSM
create_managed_hsm() {
    print_status "Creating Managed HSM: $HSM_NAME"
    print_warning "Managed HSM creation can take 15-20 minutes..."
    
    # Get current user object ID for initial admin assignment
    USER_OBJECT_ID=$(az ad signed-in-user show --query id --output tsv)
    
    az keyvault create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$HSM_NAME" \
        --hsm \
        --administrators "$USER_OBJECT_ID" \
        --location "$LOCATION" \
        --output table
    
    print_success "Managed HSM created successfully"
    print_warning "Remember to activate the HSM and create the security domain"
}

# Function to create service principal
create_service_principal() {
    print_status "Creating service principal: $SERVICE_PRINCIPAL_NAME"
    
    SP_JSON=$(az ad sp create-for-rbac \
        --name "$SERVICE_PRINCIPAL_NAME" \
        --role Contributor \
        --scopes "/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RESOURCE_GROUP_NAME" \
        --output json)
    
    SP_APP_ID=$(echo "$SP_JSON" | jq -r '.appId')
    SP_PASSWORD=$(echo "$SP_JSON" | jq -r '.password')
    SP_TENANT=$(echo "$SP_JSON" | jq -r '.tenant')
    
    print_success "Service principal created successfully"
    print_status "Application ID: $SP_APP_ID"
    print_warning "Save the password securely: $SP_PASSWORD"
    
    # Save credentials to file for reference
    cat > service-principal-credentials.json << EOF
{
    "appId": "$SP_APP_ID",
    "password": "$SP_PASSWORD",
    "tenant": "$SP_TENANT"
}
EOF
    
    print_success "Service principal credentials saved to service-principal-credentials.json"
}

# Function to assign HSM permissions
assign_hsm_permissions() {
    print_status "Assigning Managed HSM permissions to service principal"
    
    # Wait for HSM to be ready and get service principal object ID
    sleep 30
    SP_OBJECT_ID=$(az ad sp show --id "$SP_APP_ID" --query id --output tsv)
    
    # Assign Managed HSM Crypto User role
    az keyvault role assignment create \
        --hsm-name "$HSM_NAME" \
        --role "Managed HSM Crypto User" \
        --assignee "$SP_OBJECT_ID" \
        --scope /keys \
        --output table
    
    print_success "HSM permissions assigned successfully"
}

# Function to create Application Gateway
create_application_gateway() {
    print_status "Creating Application Gateway: $APP_GATEWAY_NAME"
    print_warning "This is a basic configuration. You'll need to configure TLS settings separately."
    
    az network application-gateway create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$APP_GATEWAY_NAME" \
        --location "$LOCATION" \
        --vnet-name "$VNET_NAME" \
        --subnet appgw-subnet \
        --capacity 2 \
        --sku Standard_v2 \
        --http-settings-cookie-based-affinity Disabled \
        --frontend-port 80 \
        --http-settings-port 80 \
        --http-settings-protocol Http \
        --public-ip-address "${APP_GATEWAY_NAME}-pip" \
        --output table
    
    print_success "Application Gateway created successfully"
}

# Function to display next steps
display_next_steps() {
    print_success "Infrastructure deployment completed!"
    echo
    print_status "Next steps:"
    echo "1. Activate your Managed HSM and create the security domain"
    echo "2. Generate TLS keys in the Managed HSM using the TLS Offload Library"
    echo "3. Configure Application Gateway with keyless TLS settings"
    echo "4. Test the TLS configuration"
    echo
    print_status "Resources created:"
    echo "- Resource Group: $RESOURCE_GROUP_NAME"
    echo "- Managed HSM: $HSM_NAME"
    echo "- Application Gateway: $APP_GATEWAY_NAME"
    echo "- Virtual Network: $VNET_NAME"
    echo "- Service Principal: $SERVICE_PRINCIPAL_NAME"
    echo
    print_warning "Important: Review and secure the service principal credentials in service-principal-credentials.json"
}

# Main execution
main() {
    print_status "Starting Application Gateway - Managed HSM Keyless TLS Lab Setup"
    
    check_azure_login
    create_resource_group
    create_virtual_network
    create_public_ip
    create_managed_hsm
    create_service_principal
    assign_hsm_permissions
    create_application_gateway
    display_next_steps
    
    print_success "Setup completed successfully!"
}

# Run main function
main "$@"