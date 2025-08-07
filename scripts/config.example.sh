#!/bin/bash

# Gasless ICTT Deployment Configuration Template
# Copy this file to config.sh and fill in your actual values

# =============================================================================
# TESTNET CONFIGURATION
# =============================================================================

# RPC URLs
RPC_URL_HOME_TESTNET="https://api.avax-test.network/ext/bc/C/rpc"
RPC_URL_REMOTE_TESTNET="https://subnets.avax.network/innovomark/testnet/rpc"

# Private Key (WARNING: Never commit this to version control!)
PRIVATE_KEY_TESTNET="your_private_key_here"

# Contract Addresses
REG_HOME_TESTNET="0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228"
REG_REMOTE_TESTNET="0x1706b09874052916EC4330d30EeE74b902F354AC"
MNG_TESTNET="0xD5b7DE57f5a0c6674E81Db906ccC1dDEC56d38e8"

# Blockchain IDs
BLOCKCHAIN_ID_HOME_TESTNET="0x7fc93d85c6d62c5b2ac0b519c87010ea5294012d1e407030d6acd0021cac10d5"
BLOCKCHAIN_ID_REMOTE_TESTNET="0xeaa43ceb6e928c745155585de433f487399081a800080775b0fce622b113fc95"

# Token and Forwarder Addresses
ERC20_TOKEN_ADDRESS_TESTNET="0x5425890298aed601595a70ab815c96711a31bc65"
AVACLOUD_FORWARDER_TESTNET="0xadb1cc52d50089a57c797685ea085e5cd2642c82"

# =============================================================================
# PRODUCTION CONFIGURATION
# =============================================================================

# RPC URLs
RPC_URL_HOME_PROD="https://api.avax.network/ext/bc/C/rpc"
RPC_URL_REMOTE_PROD="https://subnets.avax.network/innovo/mainnet/rpc"

# Private Key (WARNING: Never commit this to version control!)
PRIVATE_KEY_PROD="your_private_key_here"

# Contract Addresses
REG_HOME_PROD="0x7C43605E14F391720e1b37E49C78C4b03A488d98"
REG_REMOTE_PROD="0xE329B5Ff445E4976821FdCa99D6897EC43891A6c"
MNG_PROD="0xD5b7DE57f5a0c6674E81Db906ccC1dDEC56d38e8"

# Blockchain IDs
BLOCKCHAIN_ID_HOME_PROD="0x0427d4b22a2a78bcddd456742caf91b56badbff985ee19aef14573e7343fd652"
BLOCKCHAIN_ID_REMOTE_PROD="0x78e6f48866058bb35e609786d148f4e979ea9f4dcef603517e00f0ddf44490b5"

# Token and Forwarder Addresses
ERC20_TOKEN_ADDRESS_PROD="0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E"
AVACLOUD_FORWARDER_PROD="0x383eE996b783145c4d1d31144c3231d0DeDc9f34"

# =============================================================================
# DEPLOYMENT ENVIRONMENT
# =============================================================================

# Set to "testnet" or "prod" to determine which configuration to use
DEPLOYMENT_ENV="testnet"
