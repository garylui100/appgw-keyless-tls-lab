# Alternative Architecture Diagram

Since the SVG diagram might have rendering issues in some browsers, here's the architecture description:

## Application Gateway - Managed HSM Keyless TLS Architecture

```
┌─────────────┐    ┌──────────┐    ┌─────────────────────────────────────┐
│   Client    │───▶│ Internet │───▶│     Azure Application Gateway       │
│ Web Browser │    │          │    │ ┌─────────────┐ ┌─────────────────┐ │
│ Mobile App  │    └──────────┘    │ │ TLS Termina-│ │ TLS Offload     │ │
└─────────────┘                    │ │ tion & Load │ │ Library         │ │
                                   │ │ Balancing   │ │ (PKCS#11)       │ │
                                   │ └─────────────┘ └─────────────────┘ │
                                   └─────────────────────┬───────────────┘
                                                         │
┌─────────────────────┐                                 │
│ User Managed        │                                 │
│ Identity            │─────────┐                       │
│ • Assigned to       │         │                       │
│   App Gateway       │         ▼                       ▼
│ • HSM Authentication│   ┌─────────────────────────────────┐
│ • No Shared Secrets │   │     Azure Managed HSM           │
└─────────────────────┘   │ ┌─────────────┐ ┌─────────────┐ │
                          │ │ Private Keys│ │   Crypto    │ │
                          │ │ & Certifi-  │ │ Operations  │ │
                          │ │ cates       │ │             │ │
                          │ └─────────────┘ └─────────────┘ │
                          └─────────────────────────────────┘
                                           │
                                           ▼
                          ┌─────────────────────────────────┐
                          │       Backend Servers           │
                          │   • Web Applications            │
                          │   • Azure Container Apps       │
                          └─────────────────────────────────┘
```

## Data Flow:
1. **TLS Handshake**: Client initiates HTTPS connection
2. **Identity Auth**: User Managed Identity authenticates to HSM
3. **Crypto Ops**: Application Gateway uses PKCS#11 API for crypto operations
4. **Forwarding**: Encrypted traffic forwarded to backend servers

## Security Benefits:
- Keys never leave HSM boundary
- FIPS 140-2 Level 3 compliance
- Hardware-backed security
- Managed Identity authentication
- No shared secrets
- Complete audit trails
- Compliance ready architecture

## Key Features:
- Keyless TLS implementation
- Certificates stored in ARM
- Auto-scaling capabilities
- Load balancing