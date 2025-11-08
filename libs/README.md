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

1. Download the `e_akv.so` library from the official Azure Managed HSM TLS Offload Library repository, this library is for private preview testing, so please don't use it for production deployment
2. Transfer the library to the Linux Machine

## Configuration

TBD

## Official Documentation

TBD

## Security Considerations

- Store the library in a secure location
- Ensure proper file permissions (read/execute for application processes only)
- Regularly update to the latest version
- Monitor access and usage through Azure Managed HSM audit logs