# IERC20TokenRemoteLockable Interface

## Overview

The `IERC20TokenRemoteLockable` interface extends the standard ERC20 and TokenRemote functionality with user-level token locking capabilities. This allows individual users to lock portions of their token balance, preventing locked tokens from being transferred, approved, or used in cross-chain operations.

## Key Features

- **User-Level Locking**: Individual users can lock/unlock their own tokens
- **Transfer Protection**: Locked tokens cannot be transferred or approved
- **Cross-Chain Protection**: Locked tokens cannot be sent cross-chain
- **Gasless Support**: Full compatibility with gasless transactions (ERC2771)
- **Custom Errors**: Gas-efficient error handling with custom errors
- **Comprehensive Events**: Detailed event logging for all lock/unlock operations

## Interface Functions

### View Functions

#### `getLockedAmount(address account) → uint256`
Returns the amount of tokens locked for a given account.

#### `getAvailableAmount(address account) → uint256`
Returns the amount of tokens available for transfer (total balance - locked amount).

### Locking Functions

#### `lockTokens(uint256 amount)`
Locks a specified amount of tokens for the caller.
- **Events**: Emits `TokensLocked`
- **Errors**: `InsufficientBalanceToLock`, `AmountMustBeGreaterThanZero`

#### `unlockTokens(uint256 amount)`
Unlocks a specified amount of tokens for the caller.
- **Events**: Emits `TokensUnlocked`
- **Errors**: `InsufficientLockedAmountToUnlock`, `AmountMustBeGreaterThanZero`

### Overridden ERC20 Functions

All standard ERC20 functions are overridden to respect locked amounts:

#### `transfer(address to, uint256 value) → bool`
Transfers tokens, but only unlocked tokens can be transferred.
- **Errors**: `InsufficientAvailableBalance`

#### `transferFrom(address from, address to, uint256 value) → bool`
Transfers tokens using allowance, but only unlocked tokens can be transferred.
- **Errors**: `InsufficientAvailableBalance`

#### `approve(address spender, uint256 value) → bool`
Approves tokens for spending, but only unlocked tokens can be approved.
- **Errors**: `CannotApproveMoreThanAvailableBalance`

### Overridden TokenRemote Functions

#### `send(SendTokensInput calldata input, uint256 amount)`
Sends tokens cross-chain, but only unlocked tokens can be sent.
- **Errors**: `InsufficientAvailableBalance`

#### `sendAndCall(SendAndCallInput calldata input, uint256 amount)`
Sends tokens cross-chain for smart contract interaction, but only unlocked tokens can be sent.
- **Errors**: `InsufficientAvailableBalance`

## Events

### `TokensLocked(address indexed account, uint256 amount, uint256 totalLocked)`
Emitted when tokens are locked for an account.

### `TokensUnlocked(address indexed account, uint256 amount, uint256 totalLocked)`
Emitted when tokens are unlocked for an account.

## Custom Errors

### `InsufficientBalanceToLock()`
Thrown when trying to lock more tokens than the account has.

### `InsufficientLockedAmountToUnlock()`
Thrown when trying to unlock more tokens than are currently locked.

### `AmountMustBeGreaterThanZero()`
Thrown when trying to lock or unlock zero tokens.

### `InsufficientAvailableBalance()`
Thrown when trying to transfer more tokens than are available (unlocked).

### `CannotApproveMoreThanAvailableBalance()`
Thrown when trying to approve more tokens than are available (unlocked).

## Usage Examples

### Basic Locking/Unlocking

```solidity
import {IERC20TokenRemoteLockable} from "./interfaces/IERC20TokenRemoteLockable.sol";

contract MyContract {
    IERC20TokenRemoteLockable public token;
    
    function lockMyTokens(uint256 amount) external {
        token.lockTokens(amount);
    }
    
    function unlockMyTokens(uint256 amount) external {
        token.unlockTokens(amount);
    }
    
    function checkMyStatus() external view returns (uint256 balance, uint256 locked, uint256 available) {
        balance = token.balanceOf(msg.sender);
        locked = token.getLockedAmount(msg.sender);
        available = token.getAvailableAmount(msg.sender);
    }
}
```

### Safe Operations with Error Handling

```solidity
function safeLockTokens(uint256 amount) external returns (bool success) {
    try token.lockTokens(amount) {
        success = true;
    } catch {
        success = false;
    }
}

function safeLockTokensWithChecks(uint256 amount) external returns (bool success) {
    if (amount == 0) return false;
    if (token.balanceOf(msg.sender) < amount) return false;
    
    token.lockTokens(amount);
    return true;
}
```

### Transfer Only Available Tokens

```solidity
function transferAvailableTokens(address to, uint256 amount) external {
    uint256 available = token.getAvailableAmount(msg.sender);
    require(available >= amount, "Not enough available tokens");
    token.transfer(to, amount);
}
```

## Gasless Transaction Support

The interface is fully compatible with gasless transactions through ERC2771Recipient. When using a trusted forwarder, the `_msgSender()` function correctly identifies the original sender, ensuring that lock/unlock operations work correctly in gasless scenarios.

## Security Considerations

1. **User Control**: Only the token owner can lock/unlock their own tokens
2. **No Admin Override**: There are no admin functions to force unlock user tokens
3. **Consistent Behavior**: All transfer and approval functions consistently respect locked amounts
4. **Cross-Chain Safety**: Locked tokens cannot be sent cross-chain, preventing accidental loss

## Integration Notes

- The interface extends `IERC20TokenTransferrer`, `IERC20`, `IERC20Metadata`, and `ITokenRemote`
- All standard ERC20 and TokenRemote functionality is preserved
- Custom errors provide gas-efficient error handling
- Events provide comprehensive logging for all operations
- The interface is designed for upgradeable contracts

## Testing

The interface includes comprehensive test coverage:
- 50+ tests covering all functionality
- Gasless transaction testing
- Error condition testing
- Edge case testing
- Integration testing with existing TokenRemote functionality

See the test files for detailed examples of all functionality.
