# Application Gateway and Managed HSM Keyless TLS Integration Lab

A comprehensive hands-on lab demonstrating the integration process for Keyless TLS with Azure Application Gateway and Azure Managed HSM. This lab provides step-by-step guidance to configure secure TLS termination using hardware security modules without exposing private keys.

## Overview

Keyless TLS is a security enhancement that allows TLS certificate private keys to remain within a Hardware Security Module (HSM) while still enabling TLS termination at the Application Gateway. This approach provides several benefits:

- **Enhanced Security**: Private keys never leave the HSM environment
- **Compliance**: Meets regulatory requirements for cryptographic key protection
- **Centralized Key Management**: Single source of truth for cryptographic operations
- **Hardware-backed Security**: Leverages FIPS 140-2 Level 3 validated HSMs

## Architecture

The solution integrates the following Azure services:

- **Azure Application Gateway**: Provides TLS termination and load balancing
- **Azure Managed HSM**: Stores private keys and performs cryptographic operations
- **Azure Key Vault**: Optional certificate storage and management
- **PKCS#11 Interface**: Standard cryptographic token interface for HSM communication

### High-Level Architecture Diagram

![Architecture Diagram](assets/images/architecture-diagram.svg)

The architecture demonstrates the flow of keyless TLS operations:

1. **Client Connection**: Clients connect to Application Gateway over HTTPS
2. **TLS Termination**: Application Gateway terminates TLS using the TLS Offload Library
3. **Cryptographic Operations**: The TLS Offload Library communicates with Managed HSM via PKCS#11 interface
4. **Key Protection**: Private keys remain within the HSM and never leave the secure boundary
5. **Backend Communication**: Application Gateway forwards decrypted traffic to backend servers

## Prerequisites

Before starting this lab, ensure you have:

### Azure Resources
- Azure subscription with appropriate permissions
- Resource Group for deploying resources
- Virtual Network with appropriate subnets
- Service Principal with required permissions

### Required Permissions
- **Managed HSM Crypto Officer** role for initial setup
- **Managed HSM Crypto User** role for key operations
- **Application Gateway Contributor** role for gateway configuration

### Software Requirements
- Azure CLI or Azure PowerShell
- OpenSSL for certificate operations
- Azure Managed HSM TLS Offload Library

## Lab Sections

### 1. Environment Setup
- [Deploy Azure Managed HSM](docs/01-deploy-managed-hsm.md)
- [Configure Service Principals](docs/02-configure-service-principals.md)
- [Set up Role Assignments](docs/03-setup-role-assignments.md)

### 2. Key Management
- [Generate TLS Keys in Managed HSM](docs/04-generate-tls-keys.md)
- [Configure Key Labels and Access](docs/05-configure-key-access.md)

### 3. Application Gateway Configuration
- [Deploy Application Gateway](docs/06-deploy-application-gateway.md)
- [Configure TLS Offload Library](docs/07-configure-tls-offload.md)
- [Set up Keyless TLS](docs/08-setup-keyless-tls.md)

### 4. Testing and Validation
- [Test TLS Handshake](docs/09-test-tls-handshake.md)
- [Validate Security Configuration](docs/10-validate-security.md)
- [Performance Testing](docs/11-performance-testing.md)

### 5. Troubleshooting
- [Common Issues and Solutions](docs/12-troubleshooting.md)

## Key Benefits

### Security Advantages
- **Private Key Protection**: Keys never leave the HSM boundary
- **Hardware Security**: FIPS 140-2 Level 3 validated security
- **Audit Trail**: Complete logging of cryptographic operations
- **Access Controls**: Granular role-based access to keys

### Operational Benefits
- **Centralized Management**: Single point for key lifecycle management
- **High Availability**: Built-in redundancy and failover
- **Scalability**: Supports high-throughput cryptographic operations
- **Compliance**: Meets regulatory requirements for key protection

## Implementation Approaches

### Simple Approach (Recommended for Testing)
1. Create service principal for TLS Offload Library
2. Assign "Managed HSM Crypto User" role at `/keys` scope
3. Generate keys with required labels
4. Configure Application Gateway with TLS Offload Library
5. Set up key labels and service principal credentials

### Granular Approach (Production Recommended)
1. Create separate admin user with "Managed HSM Crypto Officer" role
2. Create dedicated service principals for key generation and TLS operations
3. Create custom role definitions for fine-grained access
4. Implement per-key access controls
5. Configure monitoring and alerting

## Configuration Files

### TLS Offload Library Configuration
```json
{
    "ConnectionCache": {
        "Disable": false,
        "MaxConnections": 20
    },
    "ManagedHsm": {
        "VaultUri": "https://your-hsm.managedhsm.azure.net/",
        "ClientId": "your-client-id",
        "ClientSecret": "your-client-secret"
    }
}
```

### Application Gateway SSL Configuration
Key configuration elements for enabling keyless TLS:
- PKCS#11 library path configuration
- Key label references
- Service principal authentication
- Connection caching settings

## Security Considerations

### Access Control
- Use principle of least privilege
- Implement custom role definitions
- Enable per-key access controls
- Regular access reviews

### Monitoring and Auditing
- Enable diagnostic logging
- Monitor HSM operations
- Set up security alerts
- Regular security assessments

### Network Security
- Use private endpoints where possible
- Implement network segmentation
- Configure appropriate firewall rules
- Enable Azure DDoS protection

## Performance Optimization

### Connection Caching
- Configure appropriate MaxConnections limit
- Match concurrent signing requests
- Monitor connection pool utilization
- Optimize for your workload pattern

### Key Management
- Use appropriate key sizes
- Implement key rotation policies
- Monitor key usage patterns
- Plan for capacity requirements

## Troubleshooting Guide

### Common Issues
- **Authentication Errors**: Verify service principal credentials
- **Key Not Found**: Check key labels and access permissions
- **Connection Timeouts**: Review network configuration and firewall rules
- **Performance Issues**: Optimize connection cache settings

### Diagnostic Tools
- Azure Monitor logs
- Application Gateway diagnostics
- Managed HSM audit logs
- PKCS#11 library debugging

## Resources and References

### Official Documentation
- [Azure Managed HSM TLS Offload Library](https://learn.microsoft.com/azure/key-vault/managed-hsm/tls-offload-library)
- [Application Gateway TLS Configuration](https://learn.microsoft.com/azure/application-gateway/ssl-overview)
- [PKCS#11 Standard](https://docs.oasis-open.org/pkcs11/pkcs11-base/v2.40/pkcs11-base-v2.40.html)

### Sample Code and Scripts
- [TLS Offload Library Examples](https://github.com/microsoft/AzureManagedHsmTLSOffload)
- [Azure CLI Scripts](scripts/)
- [PowerShell Modules](scripts/powershell/)

## Contributing

We welcome contributions to improve this lab! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions and support:
- Create an issue in this repository
- Check the [troubleshooting guide](docs/12-troubleshooting.md)
- Review Azure documentation links above
A hands-on lab demonstrating the integration process for Keyless TLS with Application Gateway and Managed HSM.
