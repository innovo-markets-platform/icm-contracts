# Scripts Directory

This directory contains various deployment and utility scripts for the ICM Contracts project.

## Configuration

Most scripts now support configuration via environment files to avoid hardcoding sensitive values.

### Configuration Files

**Template**: `scripts/config.example.sh`
**Configuration**: `scripts/.env` or `scripts/config.sh`

The deployment scripts will look for configuration in this order:
1. `scripts/.env` (recommended for sensitive data)
2. `scripts/config.sh` (alternative)

**To set up configuration**:
```bash
# Option 1: Using .env file (recommended)
cp scripts/config.example.sh scripts/.env
# Edit scripts/.env with your actual values

# Option 2: Using config.sh file
cp scripts/config.example.sh scripts/config.sh
# Edit scripts/config.sh with your actual values
```

**Important**: 
- Never commit `.env` files to version control
- The `.env` file is already in `.gitignore`
- Update `config.example.sh` when adding new configuration variables

### Environment Variables

The configuration supports both testnet and production environments:

```bash
# Set deployment environment
DEPLOYMENT_ENV="testnet"  # or "prod"

# Testnet configuration
RPC_URL_HOME_TESTNET="https://api.avax-test.network/ext/bc/C/rpc"
RPC_URL_REMOTE_TESTNET="https://subnets.avax.network/innovomark/testnet/rpc"
PRIVATE_KEY_TESTNET="your_private_key_here"
# ... other testnet variables

# Production configuration  
RPC_URL_HOME_PROD="https://api.avax.network/ext/bc/C/rpc"
RPC_URL_REMOTE_PROD="https://subnets.avax.network/innovo/mainnet/rpc"
PRIVATE_KEY_PROD="your_private_key_here"
# ... other production variables
```

## Available Scripts

### `deploy_gasless.sh`
**Location**: `scripts/deploy_gasless.sh`

Deploys ERC20TokenHome and ERC20TokenRemote contracts with gasless functionality using the ERC2771Recipient pattern.

**Usage**:
```bash
# From the project root
cd scripts
./deploy_gasless.sh

# Or with options
./deploy_gasless.sh --skip-confirmation --skip-jq-check
```

**Features**:
- Deploys ERC20TokenHome on the home chain
- Deploys ERC20TokenRemote on the remote chain
- Configures gasless functionality with AvaCloud forwarder
- Saves deployment results to `scripts/deployment_gasless_results.json`
- Supports testing operations after deployment
- **NEW**: Supports configuration via `.env` or `config.sh` files
- **NEW**: Supports both testnet and production environments

**Output Files**:
- `scripts/deploy_gasless_log.txt` - Deployment log
- `scripts/deployment_gasless_results.json` - Contract addresses and configuration

**Dependencies**:
- Foundry (forge)
- jq (optional, for JSON validation)
- Valid private key with sufficient funds
- Configuration file (`.env` or `config.sh`)

### Other Scripts

- `abi_bindings.sh` - Generates Go bindings from contract ABIs
- `deploy_registry.sh` - Deploys Teleporter registry
- `deploy_teleporter.sh` - Deploys Teleporter contracts
- `e2e_test.sh` - End-to-end testing script
- `install_*.sh` - Installation scripts for various components
- `lint.sh` - Code linting script
- `versions.sh` - Version management script
