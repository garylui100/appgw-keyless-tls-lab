# TLS Offload Library

This folder contains the Azure Managed HSM TLS Offload Library components required for keyless TLS integration.

## Files

### `e_akv.so`
- **Description**: Azure Managed HSM TLS Offload Library (PKCS#11 interface)
- **Purpose**: Enables Application Gateway to perform cryptographic operations using Azure Managed HSM
- **Usage**: Referenced in Application Gateway SSL configuration for keyless TLS termination
- **Platform**: Linux x64
- **FIPS 140-2 Level 3**: Compliant library for hardware security module integration

## Installation

1. Download the `e_akv.so` library from the official Azure Managed HSM TLS Offload Library repository
2. Copy to your Application Gateway or Linux VM environment
3. Configure the library path in your Application Gateway SSL settings
4. Ensure proper permissions and access to the Azure Managed HSM

## Configuration

The library requires configuration through:
- Service principal authentication (Client ID and Secret)
- Azure Managed HSM URI
- Connection caching settings
- Key label references

## Official Documentation

- [Azure Managed HSM TLS Offload Library](https://learn.microsoft.com/azure/key-vault/managed-hsm/tls-offload-library)
- [TLS Offload Library GitHub Repository](https://github.com/microsoft/AzureManagedHsmTLSOffload)

## Security Considerations

- Store the library in a secure location
- Ensure proper file permissions (read/execute for application processes only)
- Regularly update to the latest version
- Monitor access and usage through Azure Managed HSM audit logs