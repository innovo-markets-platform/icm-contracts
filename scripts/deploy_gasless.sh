#!/bin/bash

# Gasless ICTT Deployment Script
# Deploys ERC20Remote with gasless send functionality following MintController pattern

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory - now in scripts folder, need to go up to project root
SCRIPT_DIR=$(dirname "$0")
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="$SCRIPT_DIR/deploy_gasless_log.txt"
RESULTS_FILE="$SCRIPT_DIR/deployment_gasless_results.json"

# Logging functions (defined early so they can be used throughout the script)
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[${timestamp}] $1"
    echo -e "${GREEN}${message}${NC}"
    echo "$message" >> "$LOG_FILE"
}

error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[${timestamp}] ERROR: $1"
    echo -e "${RED}${message}${NC}"
    echo "$message" >> "$LOG_FILE"
}

info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[${timestamp}] INFO: $1"
    echo -e "${BLUE}${message}${NC}"
    echo "$message" >> "$LOG_FILE"
}

warn() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[${timestamp}] WARNING: $1"
    echo -e "${YELLOW}${message}${NC}"
    echo "$message" >> "$LOG_FILE"
}

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/config.sh"
ENV_FILE="$SCRIPT_DIR/.env"

# Try to load from .env file first (if it exists)
if [[ -f "$ENV_FILE" ]]; then
    log "Loading configuration from .env file..."
    # Export variables from .env file
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        
        # Remove quotes from value
        value=$(echo "$value" | sed 's/^"//;s/"$//')
        
        # Export the variable
        export "$key=$value"
    done < "$ENV_FILE"
elif [[ -f "$CONFIG_FILE" ]]; then
    log "Loading configuration from config.sh file..."
    # Source the configuration file
    source "$CONFIG_FILE"
else
    echo -e "${RED}Error: No configuration file found${NC}"
    echo -e "${YELLOW}Please create either:${NC}"
    echo -e "${BLUE}  - .env file: cp config.example.sh .env${NC}"
    echo -e "${BLUE}  - config.sh file: cp config.example.sh config.sh${NC}"
    echo -e "${YELLOW}Then edit the file with your actual configuration values${NC}"
    exit 1
fi

# Validate required environment
if [[ -z "$DEPLOYMENT_ENV" ]]; then
    echo -e "${RED}Error: DEPLOYMENT_ENV not set in configuration${NC}"
    echo -e "${YELLOW}Please set DEPLOYMENT_ENV to either 'testnet' or 'prod' in your configuration file${NC}"
    exit 1
fi

# Set configuration based on environment
if [[ "$DEPLOYMENT_ENV" == "testnet" ]]; then
    RPC_URL_HOME="$RPC_URL_HOME_TESTNET"
    RPC_URL_REMOTE="$RPC_URL_REMOTE_TESTNET"
    PRIVATE_KEY="$PRIVATE_KEY_TESTNET"
    REG_HOME="$REG_HOME_TESTNET"
    REG_REMOTE="$REG_REMOTE_TESTNET"
    MNG="$MNG_TESTNET"
    BLOCKCHAIN_ID_HOME="$BLOCKCHAIN_ID_HOME_TESTNET"
    BLOCKCHAIN_ID_REMOTE="$BLOCKCHAIN_ID_REMOTE_TESTNET"
    ERC20_TOKEN_ADDRESS="$ERC20_TOKEN_ADDRESS_TESTNET"
    AVACLOUD_FORWARDER="$AVACLOUD_FORWARDER_TESTNET"
    ENV_NAME="TESTNET"
elif [[ "$DEPLOYMENT_ENV" == "prod" ]]; then
    RPC_URL_HOME="$RPC_URL_HOME_PROD"
    RPC_URL_REMOTE="$RPC_URL_REMOTE_PROD"
    PRIVATE_KEY="$PRIVATE_KEY_PROD"
    REG_HOME="$REG_HOME_PROD"
    REG_REMOTE="$REG_REMOTE_PROD"
    MNG="$MNG_PROD"
    BLOCKCHAIN_ID_HOME="$BLOCKCHAIN_ID_HOME_PROD"
    BLOCKCHAIN_ID_REMOTE="$BLOCKCHAIN_ID_REMOTE_PROD"
    ERC20_TOKEN_ADDRESS="$ERC20_TOKEN_ADDRESS_PROD"
    AVACLOUD_FORWARDER="$AVACLOUD_FORWARDER_PROD"
    ENV_NAME="PRODUCTION"
else
    echo -e "${RED}Error: Invalid DEPLOYMENT_ENV '$DEPLOYMENT_ENV'. Must be 'testnet' or 'prod'${NC}"
    exit 1
fi

# Validate required configuration
validate_config() {
    local missing_vars=()
    
    [[ -z "$RPC_URL_HOME" ]] && missing_vars+=("RPC_URL_HOME")
    [[ -z "$RPC_URL_REMOTE" ]] && missing_vars+=("RPC_URL_REMOTE")
    [[ -z "$PRIVATE_KEY" ]] && missing_vars+=("PRIVATE_KEY")
    [[ -z "$REG_HOME" ]] && missing_vars+=("REG_HOME")
    [[ -z "$REG_REMOTE" ]] && missing_vars+=("REG_REMOTE")
    [[ -z "$MNG" ]] && missing_vars+=("MNG")
    [[ -z "$BLOCKCHAIN_ID_HOME" ]] && missing_vars+=("BLOCKCHAIN_ID_HOME")
    [[ -z "$BLOCKCHAIN_ID_REMOTE" ]] && missing_vars+=("BLOCKCHAIN_ID_REMOTE")
    [[ -z "$ERC20_TOKEN_ADDRESS" ]] && missing_vars+=("ERC20_TOKEN_ADDRESS")
    [[ -z "$AVACLOUD_FORWARDER" ]] && missing_vars+=("AVACLOUD_FORWARDER")
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required configuration variables:${NC}"
        for var in "${missing_vars[@]}"; do
            echo -e "${RED}  - $var${NC}"
        done
        echo -e "${YELLOW}Please check your configuration file and ensure all required variables are set.${NC}"
        exit 1
    fi
    
    # Check if private key is still the default placeholder
    if [[ "$PRIVATE_KEY" == "your_private_key_here" ]]; then
        echo -e "${RED}Error: PRIVATE_KEY is still set to the default placeholder value${NC}"
        echo -e "${YELLOW}Please update your configuration file with your actual private key${NC}"
        exit 1
    fi
}

# Validate configuration
validate_config

# Display environment information
log "🚀 Starting gasless ICTT deployment for $ENV_NAME environment..."
info "Configuration loaded:"
info "  - RPC URL Home: $RPC_URL_HOME"
info "  - RPC URL Remote: $RPC_URL_REMOTE"
info "  - Registry Home: $REG_HOME"
info "  - Registry Remote: $REG_REMOTE"
info "  - Manager: $MNG"
info "  - ERC20 Token: $ERC20_TOKEN_ADDRESS"
info "  - Forwarder: $AVACLOUD_FORWARDER"

# Initialize variables
ERC20_HOME_ADDRESS=""
ERC20_HOME_TX_HASH=""
ERC20_REMOTE_ADDRESS=""
ERC20_REMOTE_TX_HASH=""
SKIP_JQ_CHECK=false
SKIP_CONFIRMATION=false
jq_path=""

# Helper function to run jq (handles aliases)
run_jq() {
    if command -v jq &> /dev/null; then
        jq "$@"
    elif [[ -n "$jq_path" ]]; then
        "$jq_path" "$@"
    else
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        # Try to find jq in Windows-specific locations
        jq_path=""
        
        # Get username - try multiple methods
        local username=""
        if [[ -n "$USER" ]]; then
            username="$USER"
        elif [[ -n "$USERNAME" ]]; then
            username="$USERNAME"
        else
            username=$(whoami 2>/dev/null || echo "")
        fi
        
        # Check common Windows winget installation paths
        local possible_paths=(
            "/c/Users/$username/AppData/Local/Microsoft/WinGet/Packages/jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe/jq.exe"
            "/c/Program Files/jq/jq.exe"
            "/c/Program Files (x86)/jq/jq.exe"
            "/c/Users/$username/AppData/Local/Microsoft/WindowsApps/jq.exe"
        )
        
        for path in "${possible_paths[@]}"; do
            if [[ -f "$path" ]]; then
                jq_path="$path"
                log "Found jq at: $jq_path"
                break
            fi
        done
        
        if [[ -n "$jq_path" ]]; then
            log "Using jq from: $jq_path"
        else
            if [[ "$SKIP_JQ_CHECK" == "true" ]]; then
                warn "jq is not installed but --skip-jq-check flag was used."
                warn "Some JSON parsing features may not work properly."
                warn "Continuing without jq..."
            else
                warn "jq is not installed. Attempting to install automatically..."
                
                # Try to install jq based on OS
                local install_success=false
                
                if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
                    # Windows - try winget first
                    log "Installing jq using winget..."
                    if command -v winget &> /dev/null; then
                        if winget install jqlang.jq --silent; then
                            install_success=true
                            log "Successfully installed jq using winget"
                        else
                            log "winget installation failed, trying chocolatey..."
                            if command -v choco &> /dev/null; then
                                if choco install jq -y; then
                                    install_success=true
                                    log "Successfully installed jq using chocolatey"
                                fi
                            fi
                        fi
                    fi
                elif [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS
                    if command -v brew &> /dev/null; then
                        log "Installing jq using brew..."
                        if brew install jq; then
                            install_success=true
                            log "Successfully installed jq using brew"
                        fi
                    elif command -v port &> /dev/null; then
                        log "Installing jq using port..."
                        if sudo port install jq; then
                            install_success=true
                            log "Successfully installed jq using port"
                        fi
                    fi
                else
                    # Linux
                    if command -v apt-get &> /dev/null; then
                        log "Installing jq using apt-get..."
                        if sudo apt-get update && sudo apt-get install -y jq; then
                            install_success=true
                            log "Successfully installed jq using apt-get"
                        fi
                    elif command -v yum &> /dev/null; then
                        log "Installing jq using yum..."
                        if sudo yum install -y jq; then
                            install_success=true
                            log "Successfully installed jq using yum"
                        fi
                    elif command -v dnf &> /dev/null; then
                        log "Installing jq using dnf..."
                        if sudo dnf install -y jq; then
                            install_success=true
                            log "Successfully installed jq using dnf"
                        fi
                    elif command -v pacman &> /dev/null; then
                        log "Installing jq using pacman..."
                        if sudo pacman -S --noconfirm jq; then
                            install_success=true
                            log "Successfully installed jq using pacman"
                        fi
                    fi
                fi
                
                if [[ "$install_success" == "false" ]]; then
                    error "Failed to automatically install jq."
                    error ""
                    error "Please install jq manually using one of the following methods:"
                    error ""
                    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
                        error "  Chocolatey: choco install jq"
                        error "  winget: winget install jqlang.jq"
                    elif [[ "$OSTYPE" == "darwin"* ]]; then
                        error "  Homebrew: brew install jq"
                        error "  MacPorts: sudo port install jq"
                    else
                        error "  Ubuntu/Debian: sudo apt-get install jq"
                        error "  CentOS/RHEL: sudo yum install jq"
                        error "  Fedora: sudo dnf install jq"
                        error "  Arch: sudo pacman -S jq"
                    fi
                    error "  Or download from: https://stedolan.github.io/jq/download/"
                    error ""
                    error "After installing jq, run this script again."
                    error ""
                    error "Alternatively, you can try running the script with the --skip-jq-check flag"
                    error "if you want to proceed without jq (some features may not work properly)."
                    exit 1
                fi
            fi
        fi
    else
        log "jq is already installed and available"
    fi
    
    # Check if we're in the right directory
    if [[ ! -f "foundry.toml" ]] && [[ ! -f "../foundry.toml" ]] && [[ ! -f "../../foundry.toml" ]]; then
        error "This script must be run from the project root directory (where foundry.toml is located) or from a subdirectory"
        error "Current directory: $(pwd)"
        error "Please navigate to the project root and try again."
        exit 1
    fi
    
    # Set project root
    if [[ -f "foundry.toml" ]]; then
        PROJECT_ROOT="$(pwd)"
    elif [[ -f "../foundry.toml" ]]; then
        PROJECT_ROOT="$(cd .. && pwd)"
    elif [[ -f "../../foundry.toml" ]]; then
        PROJECT_ROOT="$(cd ../.. && pwd)"
    fi
    
    log "Project root: $PROJECT_ROOT"
    
    # Check if forge is available
    if ! command -v forge &> /dev/null; then
        error "forge is not installed or not in PATH"
        error "Please install Foundry: https://getfoundry.sh/"
        exit 1
    fi
    
    # Check if cast is available
    if ! command -v cast &> /dev/null; then
        error "cast is not installed or not in PATH"
        error "Please install Foundry: https://getfoundry.sh/"
        exit 1
    fi
    
    # Try to compile the project
    log "Compiling project..."
    if ! forge build --silent; then
        error "Foundry build failed. Please check your remappings and dependencies."
        exit 1
    fi
    
    log "Prerequisites check passed"
}

# Deploy ERC20Home (standard, no gasless needed)
deploy_erc20_home() {
    log "=========================================================================="
    log "Deploying ERC20Home on Home"
    
    # Deploy the contract with flags before contract spec (fixes Foundry v1.0.0 argument parsing bug)
    local command="cd $PROJECT_ROOT && forge create \
        --broadcast \
        --json \
        --rpc-url $RPC_URL_HOME \
        --private-key $PRIVATE_KEY \
        contracts/ictt/TokenHome/ERC20TokenHome.sol:ERC20TokenHome \
        --constructor-args \
        $REG_HOME \
        $MNG \
        1 \
        $ERC20_TOKEN_ADDRESS \
        6 \
        $AVACLOUD_FORWARDER"
    
    log "Executing command: $command"
    
    local output
    if ! output=$(eval "$command" 2>&1); then
        error "ERC20Home deployment command failed"
        error "Command output: $output"
        return 1
    fi
    
    log "Deployment output: $output"
    
    # Try to extract contract address and transaction hash from forge output
    local contract_address=""
    local tx_hash=""
    
    # Check for forge create JSON output format (when using --json flag)
    if echo "$output" | grep -q '"deployedTo"' && echo "$output" | grep -q '"transactionHash"'; then
        if command -v jq &> /dev/null || [[ -n "$jq_path" ]]; then
            contract_address=$(echo "$output" | run_jq -r '.deployedTo // empty' 2>/dev/null)
            tx_hash=$(echo "$output" | run_jq -r '.transactionHash // empty' 2>/dev/null)
        else
            # Fallback JSON parsing without jq
            contract_address=$(echo "$output" | grep -o '"deployedTo"[[:space:]]*:[[:space:]]*"0x[a-fA-F0-9]\{40\}"' | cut -d'"' -f4)
            tx_hash=$(echo "$output" | grep -o '"transactionHash"[[:space:]]*:[[:space:]]*"0x[a-fA-F0-9]\{64\}"' | cut -d'"' -f4)
        fi
        
        # Debug logging for troubleshooting
        if [[ -n "$contract_address" ]]; then
            log "DEBUG: Extracted contract address from JSON: $contract_address"
        fi
        if [[ -n "$tx_hash" ]]; then
            log "DEBUG: Extracted transaction hash from JSON: $tx_hash"
        else
            log "DEBUG: Could not extract transaction hash from JSON output"
        fi
    # Fallback: Check for old forge create text output format
    elif echo "$output" | grep -q "Deployed to:"; then
        contract_address=$(echo "$output" | grep -o "Deployed to: 0x[a-fA-F0-9]\{40\}" | cut -d' ' -f3)
        # Try both "Transaction:" and "Transaction hash:" formats
        tx_hash=$(echo "$output" | grep -o "Transaction hash: 0x[a-fA-F0-9]\{64\}" | cut -d' ' -f3)
        if [[ -z "$tx_hash" ]]; then
            tx_hash=$(echo "$output" | grep -o "Transaction: 0x[a-fA-F0-9]\{64\}" | cut -d' ' -f2)
        fi
        
        # Debug logging for troubleshooting
        if [[ -n "$contract_address" ]]; then
            log "DEBUG: Extracted contract address: $contract_address"
        fi
        if [[ -n "$tx_hash" ]]; then
            log "DEBUG: Extracted transaction hash: $tx_hash"
        else
            log "DEBUG: Could not extract transaction hash from output"
        fi
    # Check for JSON output format (cast send --json)
    elif echo "$output" | grep -q '"contractAddress"'; then
        if command -v jq &> /dev/null || [[ -n "$jq_path" ]]; then
            contract_address=$(echo "$output" | run_jq -r '.contractAddress // empty' 2>/dev/null)
            tx_hash=$(echo "$output" | run_jq -r '.transactionHash // empty' 2>/dev/null)
        else
            # Fallback JSON parsing without jq
            contract_address=$(echo "$output" | grep -o '"contractAddress"[[:space:]]*:[[:space:]]*"0x[a-fA-F0-9]\{40\}"' | cut -d'"' -f4)
            tx_hash=$(echo "$output" | grep -o '"transactionHash"[[:space:]]*:[[:space:]]*"0x[a-fA-F0-9]\{64\}"' | cut -d'"' -f4)
        fi
    # Handle Foundry's --skip-simulation output format (transaction data but no "Deployed to:")
    elif echo "$output" | grep -q '"nonce"' && echo "$output" | grep -q '"from"'; then
        log "INFO: Transaction data detected - deployment likely successful despite 'dry run' warning"
        log "INFO: This is normal Foundry behavior with --skip-simulation flag"
        
        # Try to extract nonce for tracking
        local nonce=$(echo "$output" | grep -o '"nonce": "0x[a-fA-F0-9]*"' | cut -d'"' -f4)
        if [[ -n "$nonce" ]]; then
            log "DEBUG: Transaction nonce: $nonce"
        fi
        
        # Set placeholder values since we can't extract the actual contract address from this format
        contract_address="check_blockchain_explorer"
        tx_hash="check_nonce_${nonce:-unknown}"
        
        log "IMPORTANT: Contract address not extractable from this output format"
        log "IMPORTANT: Please check the blockchain explorer using the transaction nonce above"
    fi
    
    if [[ -z "$contract_address" ]]; then
        error "ERC20Home deployment failed - could not extract contract address"
        error "Full output: $output"
        return 1
    fi
    
    if [[ -z "$tx_hash" ]]; then
        warn "ERC20Home deployment succeeded but could not extract transaction hash"
        tx_hash="unknown"
    fi
    
    log "ERC20 Home Contract Address: $contract_address"
    log "ERC20 Home Transaction Hash: $tx_hash"
    
    ERC20_HOME_ADDRESS="$contract_address"
    ERC20_HOME_TX_HASH="$tx_hash"
    
    log "ERC20Home deployment successful"
    return 0
}

# Deploy ERC20Remote with gasless functionality
deploy_erc20_remote() {
    log "=========================================================================="
    log "Deploying ERC20Remote with gasless functionality on Remote"
    
    # Deploy the contract with flags before contract spec (fixes Foundry v1.0.0 argument parsing bug)
    local command="cd $PROJECT_ROOT && forge create \
        --broadcast \
        --json \
        --rpc-url $RPC_URL_REMOTE \
        --private-key $PRIVATE_KEY \
        contracts/ictt/TokenRemote/ERC20TokenRemote.sol:ERC20TokenRemote \
        --constructor-args \
        '($REG_REMOTE,$MNG,1,$BLOCKCHAIN_ID_HOME,$ERC20_HOME_ADDRESS,6)' \
        'Innovo USDC' \
        'IUSDC' \
        6 \
        $AVACLOUD_FORWARDER"
    
    log "Executing command: $command"
    
    local output
    if ! output=$(eval "$command" 2>&1); then
        error "ERC20Remote deployment command failed"
        error "Command output: $output"
        return 1
    fi
    
    log "Deployment output: $output"
    
    # Try to extract contract address and transaction hash from forge output
    local contract_address=""
    local tx_hash=""
    
    # Check for forge create JSON output format (when using --json flag)
    if echo "$output" | grep -q '"deployedTo"' && echo "$output" | grep -q '"transactionHash"'; then
        if command -v jq &> /dev/null || [[ -n "$jq_path" ]]; then
            contract_address=$(echo "$output" | run_jq -r '.deployedTo // empty' 2>/dev/null)
            tx_hash=$(echo "$output" | run_jq -r '.transactionHash // empty' 2>/dev/null)
        else
            # Fallback JSON parsing without jq
            contract_address=$(echo "$output" | grep -o '"deployedTo"[[:space:]]*:[[:space:]]*"0x[a-fA-F0-9]\{40\}"' | cut -d'"' -f4)
            tx_hash=$(echo "$output" | grep -o '"transactionHash"[[:space:]]*:[[:space:]]*"0x[a-fA-F0-9]\{64\}"' | cut -d'"' -f4)
        fi
        
        # Debug logging for troubleshooting
        if [[ -n "$contract_address" ]]; then
            log "DEBUG: Extracted contract address from JSON: $contract_address"
        fi
        if [[ -n "$tx_hash" ]]; then
            log "DEBUG: Extracted transaction hash from JSON: $tx_hash"
        else
            log "DEBUG: Could not extract transaction hash from JSON output"
        fi
    # Fallback: Check for old forge create text output format
    elif echo "$output" | grep -q "Deployed to:"; then
        contract_address=$(echo "$output" | grep -o "Deployed to: 0x[a-fA-F0-9]\{40\}" | cut -d' ' -f3)
        # Try both "Transaction:" and "Transaction hash:" formats
        tx_hash=$(echo "$output" | grep -o "Transaction hash: 0x[a-fA-F0-9]\{64\}" | cut -d' ' -f3)
        if [[ -z "$tx_hash" ]]; then
            tx_hash=$(echo "$output" | grep -o "Transaction: 0x[a-fA-F0-9]\{64\}" | cut -d' ' -f2)
        fi
        
        # Debug logging for troubleshooting
        if [[ -n "$contract_address" ]]; then
            log "DEBUG: Extracted contract address: $contract_address"
        fi
        if [[ -n "$tx_hash" ]]; then
            log "DEBUG: Extracted transaction hash: $tx_hash"
        else
            log "DEBUG: Could not extract transaction hash from output"
        fi
    # Check for JSON output format (cast send --json)
    elif echo "$output" | grep -q '"contractAddress"'; then
        if command -v jq &> /dev/null || [[ -n "$jq_path" ]]; then
            contract_address=$(echo "$output" | run_jq -r '.contractAddress // empty' 2>/dev/null)
            tx_hash=$(echo "$output" | run_jq -r '.transactionHash // empty' 2>/dev/null)
        else
            # Fallback JSON parsing without jq
            contract_address=$(echo "$output" | grep -o '"contractAddress"[[:space:]]*:[[:space:]]*"0x[a-fA-F0-9]\{40\}"' | cut -d'"' -f4)
            tx_hash=$(echo "$output" | grep -o '"transactionHash"[[:space:]]*:[[:space:]]*"0x[a-fA-F0-9]\{64\}"' | cut -d'"' -f4)
        fi
    # Handle Foundry's --skip-simulation output format (transaction data but no "Deployed to:")
    elif echo "$output" | grep -q '"nonce"' && echo "$output" | grep -q '"from"'; then
        log "INFO: Transaction data detected - deployment likely successful despite 'dry run' warning"
        log "INFO: This is normal Foundry behavior with --skip-simulation flag"
        
        # Try to extract nonce for tracking
        local nonce=$(echo "$output" | grep -o '"nonce": "0x[a-fA-F0-9]*"' | cut -d'"' -f4)
        if [[ -n "$nonce" ]]; then
            log "DEBUG: Transaction nonce: $nonce"
        fi
        
        # Set placeholder values since we can't extract the actual contract address from this format
        contract_address="check_blockchain_explorer"
        tx_hash="check_nonce_${nonce:-unknown}"
        
        log "IMPORTANT: Contract address not extractable from this output format"
        log "IMPORTANT: Please check the blockchain explorer using the transaction nonce above"
    fi
    
    if [[ -z "$contract_address" ]]; then
        error "ERC20Remote deployment failed - could not extract contract address"
        error "Full output: $output"
        return 1
    fi
    
    if [[ -z "$tx_hash" ]]; then
        warn "ERC20Remote deployment succeeded but could not extract transaction hash"
        tx_hash="unknown"
    fi
    
    log "ERC20 Remote Contract Address: $contract_address"
    log "ERC20 Remote Transaction Hash: $tx_hash"
    
    ERC20_REMOTE_ADDRESS="$contract_address"
    ERC20_REMOTE_TX_HASH="$tx_hash"
    
    log "ERC20Remote deployment successful (ERC2771Recipient pattern)"
    return 0
}

# Register contracts
register_contracts() {
    log "=========================================================================="
    log "Registering contracts"
    
    if [[ -z "$ERC20_REMOTE_ADDRESS" || -z "$ERC20_HOME_ADDRESS" ]]; then
        error "Cannot register contracts - missing contract addresses"
        return 1
    fi
    
    local command="cast send --private-key=$PRIVATE_KEY --rpc-url=$RPC_URL_REMOTE \
        $ERC20_REMOTE_ADDRESS \"registerWithHome((address,uint256))\" \
        \"($ERC20_HOME_ADDRESS,0)\""
    
    log "Executing registration command: $command"
    
    local output
    if ! output=$(eval "$command" 2>&1); then
        error "Contract registration failed"
        error "Command output: $output"
        return 1
    fi
    
    log "Registration output: $output"
    log "Contracts registered successfully"
    return 0
}

# Approve tokens for transfer
approve_tokens() {
    log "=========================================================================="
    log "Approving tokens for transfer"
    
    if [[ -z "$ERC20_HOME_ADDRESS" ]]; then
        error "Cannot approve tokens - missing ERC20Home address"
        return 1
    fi
    
    local command="cast send --private-key=$PRIVATE_KEY --rpc-url=$RPC_URL_HOME \
        $ERC20_TOKEN_ADDRESS \"approve(address,uint256)\" \
        \"$ERC20_HOME_ADDRESS\" \"2\""
    
    log "Executing approval command: $command"
    
    local output
    if ! output=$(eval "$command" 2>&1); then
        error "Token approval failed"
        error "Command output: $output"
        return 1
    fi
    
    log "Approval output: $output"
    log "Tokens approved successfully"
    return 0
}

# Send tokens cross-chain (Home to Remote)
send_tokens() {
    log "=========================================================================="
    log "Sending tokens cross-chain (Home to Remote)"
    
    if [[ -z "$ERC20_HOME_ADDRESS" || -z "$ERC20_REMOTE_ADDRESS" ]]; then
        error "Cannot send tokens - missing contract addresses"
        return 1
    fi
    
    local command="cast send --private-key=$PRIVATE_KEY --rpc-url=$RPC_URL_HOME \
        $ERC20_HOME_ADDRESS \"send((bytes32,address,address,address,uint256,uint256,uint256,address),uint256)\" \
        \"($BLOCKCHAIN_ID_REMOTE,$ERC20_REMOTE_ADDRESS,$MNG,$ERC20_TOKEN_ADDRESS,0,0,200000,0x0000000000000000000000000000000000000000)\" \"1\""
    
    log "Executing send command: $command"
    
    local output
    if ! output=$(eval "$command" 2>&1); then
        error "Token send failed"
        error "Command output: $output"
        return 1
    fi
    
    log "Send output: $output"
    log "Tokens sent successfully (Home to Remote)"
    return 0
}

# Wait for cross-chain message processing
wait_for_message_processing() {
    log "=========================================================================="
    log "Waiting for cross-chain message processing..."
    
    # Wait for 30 seconds to allow message processing
    sleep 30
    
    log "Message processing wait completed"
    return 0
}

# Test gasless send from Remote to Home
test_gasless_send() {
    log "=========================================================================="
    log "Testing gasless send (Remote to Home)"
    
    if [[ -z "$ERC20_REMOTE_ADDRESS" ]]; then
        error "Cannot test gasless send - missing ERC20Remote address"
        return 1
    fi
    
    # First, check balance on remote chain
    log "Checking balance on remote chain..."
    local balance_command="cast call --rpc-url $RPC_URL_REMOTE \
        $ERC20_REMOTE_ADDRESS \"balanceOf(address)\" \"$MNG\""
    
    log "Executing balance check command: $balance_command"
    
    local balance_output
    if ! balance_output=$(eval "$balance_command" 2>&1); then
        error "Failed to check balance"
        error "Command output: $balance_output"
        return 1
    fi
    
    log "Balance on remote chain: $balance_output"
    
    # Test gasless send using ERC2771Recipient pattern
    log "Note: Gasless send uses ERC2771Recipient pattern with AvaCloud forwarder"
    log "The contract is now relayer compliant and supports gasless transactions"
    log "For actual gasless testing, use the gasless_send_client.js script"
    
    return 0
}

# Save deployment results
save_results() {
    log "=========================================================================="
    log "Saving deployment results"
    
    # Ensure we have at least some contract addresses
    if [[ -z "$ERC20_HOME_ADDRESS" && -z "$ERC20_REMOTE_ADDRESS" ]]; then
        error "No contract addresses to save - deployment may have failed"
        return 1
    fi
    
    # Create a backup of the previous results file if it exists
    if [[ -f "$RESULTS_FILE" ]]; then
        local backup_file="${RESULTS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        log "Backing up previous results to: $backup_file"
        cp "$RESULTS_FILE" "$backup_file"
    fi
    
    cat > "$RESULTS_FILE" << EOF
{
    "deployment": {
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "network": {
            "home": {
                "rpcUrl": "$RPC_URL_HOME",
                "blockchainId": "$BLOCKCHAIN_ID_HOME"
            },
            "remote": {
                "rpcUrl": "$RPC_URL_REMOTE",
                "blockchainId": "$BLOCKCHAIN_ID_REMOTE"
            }
        },
        "contracts": {
            "erc20Home": {
                "contractAddress": "$ERC20_HOME_ADDRESS",
                "transactionHash": "$ERC20_HOME_TX_HASH"
            },
            "erc20Remote": {
                "contractAddress": "$ERC20_REMOTE_ADDRESS",
                "transactionHash": "$ERC20_REMOTE_TX_HASH"
            }
        },
        "gasless": {
            "forwarder": "$AVACLOUD_FORWARDER",
            "signatory": "$MNG"
        },
        "status": "completed"
    }
}
EOF
    
    log "Results saved to: $RESULTS_FILE"
    
    # Also log the results to the log file
    log "Deployment Results Summary:"
    log "  ERC20Home Address: $ERC20_HOME_ADDRESS"
    log "  ERC20Home TX Hash: $ERC20_HOME_TX_HASH"
    log "  ERC20Remote Address: $ERC20_REMOTE_ADDRESS"
    log "  ERC20Remote TX Hash: $ERC20_REMOTE_TX_HASH"
    log "  Forwarder: $AVACLOUD_FORWARDER"
    
    # Validate JSON if jq is available
    if command -v jq &> /dev/null || [[ -n "$jq_path" ]]; then
        if ! run_jq empty "$RESULTS_FILE" 2>/dev/null; then
            error "Generated JSON file is invalid"
            return 1
        fi
        log "JSON validation passed"
    else
        warn "jq not available - skipping JSON validation"
    fi
}

# Display final summary
display_summary() {
    log "=========================================================================="
    log "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉"
    log "=========================================================================="
    log ""
    log "📋 CONTRACT ADDRESSES:"
    log "  🏠 ERC20Home:     $ERC20_HOME_ADDRESS"
    log "  🌐 ERC20Remote:   $ERC20_REMOTE_ADDRESS"
    log ""
    log "🔗 TRANSACTION HASHES:"
    log "  🏠 ERC20Home:     $ERC20_HOME_TX_HASH"
    log "  🌐 ERC20Remote:   $ERC20_REMOTE_TX_HASH"
    log ""
    log "⚡ GASLESS CONFIGURATION:"
    log "  🔄 Forwarder:     $AVACLOUD_FORWARDER"
    log "  👤 Signatory:     $MNG"
    log ""
    log "📁 FILES GENERATED:"
    log "  📄 Log file:      $LOG_FILE"
    log "  📊 Results JSON:  $RESULTS_FILE"
    log ""
    
    # Check if testing was performed by looking for balance check
    if grep -q "Balance on remote chain:" "$LOG_FILE"; then
        log "🚀 TESTING COMPLETED:"
        log "  1. ✅ Regular send from Home to Remote (completed)"
        log "  2. ✅ Balance check on Remote chain (completed)"
        log "  3. 🔄 Test gasless send from Remote to Home"
        log "  4. 📝 Use deployment results for client testing"
        log ""
        log "🧪 FOR GASLESS TESTING, RUN:"
        log "  cd $PROJECT_ROOT && node $PROJECT_ROOT/tests/flows/ictt/gasless_send_client.js"
    else
        log "⏭️  TESTING SKIPPED:"
        log "  • Contract deployment and registration completed"
        log "  • Testing operations were skipped by user"
        log "  • Manual testing can be performed using the contract addresses"
        log ""
        log "🔧 MANUAL TESTING OPTIONS:"
        log "  • Use contract addresses from: $RESULTS_FILE"
        log "  • Run gasless testing: node $PROJECT_ROOT/tests/flows/ictt/gasless_send_client.js"
        log "  • Approve tokens manually: cast send --private-key=<KEY> --rpc-url=<RPC> <TOKEN> 'approve(address,uint256)' <HOME_ADDRESS> <AMOUNT>"
        log "  • Send tokens manually: cast send --private-key=<KEY> --rpc-url=<RPC> <HOME_ADDRESS> 'send(...)' <PARAMS>"
    fi
    
    log ""
    log "=========================================================================="
}

# User confirmation function
confirm_testing() {
    log "=========================================================================="
    log "📋 DEPLOYMENT SUMMARY"
    log "=========================================================================="
    log ""
    log "✅ Successfully deployed contracts:"
    log "  🏠 ERC20Home:     $ERC20_HOME_ADDRESS"
    log "  🌐 ERC20Remote:   $ERC20_REMOTE_ADDRESS"
    log ""
    log "✅ Successfully registered contracts"
    log ""
    log "🔄 NEXT PHASE: Testing Operations"
    log "  • Approve tokens for transfer"
    log "  • Send tokens cross-chain (Home to Remote)"
    log "  • Wait for message processing"
    log "  • Test gasless send functionality"
    log ""
    
    # Skip confirmation if flag is set
    if [[ "$SKIP_CONFIRMATION" == "true" ]]; then
        log "⏭️  Skipping confirmation (--skip-confirmation flag used)"
        log "Proceeding with testing operations automatically..."
        return 0
    fi
    
    while true; do
        echo -e "${YELLOW}Do you want to proceed with testing operations? (y/n):${NC} "
        read -r response
        
        case $response in
            [Yy]|[Yy][Ee][Ss])
                log "User confirmed: Proceeding with testing operations..."
                return 0
                ;;
            [Nn]|[Nn][Oo])
                log "User declined: Skipping testing operations."
                return 1
                ;;
            *)
                echo -e "${RED}Please enter 'y' or 'n'${NC}"
                ;;
        esac
    done
}

# Main execution
main() {
    # Initialize log file
    echo "Gasless ICTT Deployment Log - $(date)" > "$LOG_FILE"
    
    log "🚀 Starting gasless ICTT deployment..."
    log "📁 Script directory: $SCRIPT_DIR"
    log "📄 Log file: $LOG_FILE"
    log "📊 Results file: $RESULTS_FILE"
    
    check_prerequisites
    
    if ! deploy_erc20_home; then
        error "ERC20Home deployment failed"
        save_results  # Save what we have so far
        exit 1
    fi
    
    if ! deploy_erc20_remote; then
        error "ERC20Remote deployment failed"
        save_results  # Save what we have so far
        exit 1
    fi
    
    if ! register_contracts; then
        error "Contract registration failed"
        save_results  # Save what we have so far
        exit 1
    fi
    
    # Ask user if they want to proceed with testing
    if ! confirm_testing; then
        log "=========================================================================="
        log "⏭️  SKIPPING TESTING OPERATIONS"
        log "=========================================================================="
        log ""
        log "✅ Deployment completed successfully!"
        log "📋 Contract addresses have been saved to: $RESULTS_FILE"
        log ""
        log "🔧 Manual testing can be performed using:"
        log "  • Contract addresses: $RESULTS_FILE"
        log "  • Gasless testing: node $PROJECT_ROOT/tests/flows/ictt/gasless_send_client.js"
        log ""
        save_results
        display_summary
        return 0
    fi
    
    if ! approve_tokens; then
        error "Token approval failed"
        save_results  # Save what we have so far
        exit 1
    fi
    
    if ! send_tokens; then
        error "Token send failed"
        save_results  # Save what we have so far
        exit 1
    fi
    
    if ! wait_for_message_processing; then
        error "Message processing wait failed"
        save_results  # Save what we have so far
        exit 1
    fi
    
    if ! test_gasless_send; then
        error "Gasless send test failed"
        save_results  # Save what we have so far
        exit 1
    fi
    
    save_results
    display_summary
}

# Run main function
main "$@" 