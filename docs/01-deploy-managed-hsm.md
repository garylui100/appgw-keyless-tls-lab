# Deploy Azure Managed HSM

This guide walks you through deploying an Azure Managed HSM instance for the keyless TLS integration lab.

## Overview

Azure Managed HSM (Hardware Security Module) provides FIPS 140-2 Level 3 validated security for storing and managing cryptographic keys. In this lab, the Managed HSM will store TLS private keys and perform cryptographic operations without exposing the keys outside the HSM boundary.

## Prerequisites

- Azure subscription with appropriate permissions
- Resource group created for the lab
- Azure CLI or Azure PowerShell installed and configured

## Required Permissions

To deploy and manage Managed HSM, you need:
- **Owner** or **Contributor** permissions on the subscription or resource group
- **User Access Administrator** permissions to assign HSM roles

## Deployment Steps

### Using Azure CLI

1. **Create the Managed HSM**

```bash
# Set variables
RESOURCE_GROUP="rg-appgw-mhsm-lab"
HSM_NAME="mhsm-keyless-tls-lab"
LOCATION="East US 2"

# Get your user object ID for initial admin assignment
USER_OBJECT_ID=$(az ad signed-in-user show --query id --output tsv)

# Create the Managed HSM
az keyvault create \
    --resource-group $RESOURCE_GROUP \
    --name $HSM_NAME \
    --hsm \
    --administrators $USER_OBJECT_ID \
    --location $LOCATION \
    --retention-days 7
```

2. **Wait for Deployment**

The Managed HSM deployment typically takes 15-20 minutes. You can check the status:

```bash
az keyvault show --name $HSM_NAME --resource-group $RESOURCE_GROUP --query "properties.provisioningState"
```

### Using Azure PowerShell

```powershell
# Set variables
$ResourceGroupName = "rg-appgw-mhsm-lab"
$HSMName = "mhsm-keyless-tls-lab"
$Location = "East US 2"

# Get current user object ID
$currentUser = Get-AzADUser -SignedIn

# Create the Managed HSM
New-AzKeyVaultManagedHsm -ResourceGroupName $ResourceGroupName -Name $HSMName -Location $Location -Administrator $currentUser.Id
```

## Post-Deployment Configuration

### 1. Activate the HSM

After deployment, you must activate the HSM and create a security domain:

```bash
# Download security domain (this creates the security domain)
az keyvault security-domain download --hsm-name $HSM_NAME --sd-wrapping-keys ./sd-wrapping-keys.json --sd-quorum 2 --security-domain-file ./security-domain.json
```

### 2. Verify HSM Status

```bash
# Check HSM status
az keyvault show --name $HSM_NAME --resource-group $RESOURCE_GROUP --query "properties"
```

The HSM should show a status of "Provisioned" and "Activated".

### 3. Create Initial Role Assignments

Assign necessary roles for the lab:

```bash
# Create service principal for TLS operations (if not already created)
SP_JSON=$(az ad sp create-for-rbac --name "sp-tls-offload" --role Contributor)
SP_OBJECT_ID=$(echo $SP_JSON | jq -r '.id')

# Assign Managed HSM Crypto User role for key operations
az keyvault role assignment create \
    --hsm-name $HSM_NAME \
    --role "Managed HSM Crypto User" \
    --assignee $SP_OBJECT_ID \
    --scope /keys
```

## Validation

### Verify HSM Connectivity

Test that you can connect to the HSM:

```bash
# List existing keys (should be empty initially)
az keyvault key list --hsm-name $HSM_NAME
```

### Check Role Assignments

```bash
# List role assignments
az keyvault role assignment list --hsm-name $HSM_NAME
```

## Security Considerations

### Access Control
- Follow the principle of least privilege
- Use custom role definitions for fine-grained access
- Regularly review and audit role assignments

### Network Security
- Consider using private endpoints for production deployments
- Implement network access restrictions if required
- Enable diagnostic logging for security monitoring

### Backup and Recovery
- Maintain secure backups of the security domain
- Store security domain keys in multiple secure locations
- Document recovery procedures

## Common Issues and Solutions

### Issue: HSM Creation Fails
**Solution**: Verify you have sufficient permissions and the HSM name is globally unique.

### Issue: Cannot Activate HSM
**Solution**: Ensure you have the "Managed HSM Administrator" role and the HSM is in "Provisioned" state.

### Issue: Role Assignment Fails
**Solution**: Check that the service principal exists and you have "User Access Administrator" permissions.

## Cost Optimization

- Managed HSM is billed per HSM instance per hour
- Consider the appropriate SKU for your needs (Standard B1 vs Premium)
- Plan for regional deployment to minimize data transfer costs

## Next Steps

After successfully deploying the Managed HSM:

1. [Configure Service Principals](02-configure-service-principals.md)
2. [Set up Role Assignments](03-setup-role-assignments.md)
3. [Generate TLS Keys](04-generate-tls-keys.md)

## Additional Resources

- [Azure Managed HSM Documentation](https://docs.microsoft.com/azure/key-vault/managed-hsm/)
- [Managed HSM Best Practices](https://docs.microsoft.com/azure/key-vault/managed-hsm/best-practices)
- [FIPS 140-2 Compliance](https://docs.microsoft.com/azure/key-vault/managed-hsm/overview#fips-140-2-level-3-compliance)