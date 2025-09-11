// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.25;

import {IERC20TokenTransferrer, SendTokensInput, SendAndCallInput} from "./IERC20TokenTransferrer.sol";
import {IERC20} from "@openzeppelin/contracts@5.0.2/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/IERC20Metadata.sol";
import {ITokenRemote, TokenRemoteSettings} from "../TokenRemote/interfaces/ITokenRemote.sol";

/**
 * @title IERC20TokenRemoteLockable
 * @notice Interface for an ERC20 Token Remote contract with user-level token locking functionality.
 * This interface extends the standard ERC20 and TokenRemote functionality with the ability
 * for users to lock and unlock their tokens, preventing locked tokens from being transferred.
 * 
 * @custom:security-contact https://github.com/ava-labs/icm-contracts/blob/main/SECURITY.md
 */
interface IERC20TokenRemoteLockable is IERC20TokenTransferrer, IERC20, IERC20Metadata, ITokenRemote {
    
    // ============ Events ============
    
    /**
     * @notice Emitted when tokens are locked for an account
     * @param account The account that locked the tokens
     * @param amount The amount of tokens locked
     * @param totalLocked The total amount of tokens locked for the account after this operation
     */
    event TokensLocked(address indexed account, uint256 amount, uint256 totalLocked);
    
    /**
     * @notice Emitted when tokens are unlocked for an account
     * @param account The account that unlocked the tokens
     * @param amount The amount of tokens unlocked
     * @param totalLocked The total amount of tokens locked for the account after this operation
     */
    event TokensUnlocked(address indexed account, uint256 amount, uint256 totalLocked);
    
    // ============ Custom Errors ============
    
    /**
     * @notice Thrown when trying to lock more tokens than the account has
     */
    error InsufficientBalanceToLock();
    
    /**
     * @notice Thrown when trying to unlock more tokens than are currently locked
     */
    error InsufficientLockedAmountToUnlock();
    
    /**
     * @notice Thrown when trying to lock or unlock zero tokens
     */
    error AmountMustBeGreaterThanZero();
    
    /**
     * @notice Thrown when trying to transfer more tokens than are available (unlocked)
     */
    error InsufficientAvailableBalance();
    
    /**
     * @notice Thrown when trying to approve more tokens than are available (unlocked)
     */
    error CannotApproveMoreThanAvailableBalance();
    
    // ============ View Functions ============
    
    /**
     * @notice Returns the amount of tokens locked for a given account
     * @param account The account to check locked amount for
     * @return The amount of tokens locked for the account
     */
    function getLockedAmount(address account) external view returns (uint256);
    
    /**
     * @notice Returns the amount of tokens available for transfer for a given account
     * Available amount = total balance - locked amount
     * @param account The account to check available amount for
     * @return The amount of tokens available for transfer
     */
    function getAvailableAmount(address account) external view returns (uint256);
    
    // ============ Locking Functions ============
    
    /**
     * @notice Locks a specified amount of tokens for the caller
     * Locked tokens cannot be transferred, approved, or used in cross-chain operations
     * @param amount The amount of tokens to lock
     * @dev Emits {TokensLocked} event on success
     * @dev Reverts with {InsufficientBalanceToLock} if account doesn't have enough tokens
     * @dev Reverts with {AmountMustBeGreaterThanZero} if amount is zero
     */
    function lockTokens(uint256 amount) external;
    
    /**
     * @notice Unlocks a specified amount of tokens for the caller
     * Unlocked tokens become available for transfer and other operations
     * @param amount The amount of tokens to unlock
     * @dev Emits {TokensUnlocked} event on success
     * @dev Reverts with {InsufficientLockedAmountToUnlock} if not enough tokens are locked
     * @dev Reverts with {AmountMustBeGreaterThanZero} if amount is zero
     */
    function unlockTokens(uint256 amount) external;
    
    // ============ Overridden ERC20 Functions ============
    
    /**
     * @notice Transfers tokens from the caller to another account
     * @param to The recipient address
     * @param value The amount of tokens to transfer
     * @return success True if the transfer was successful
     * @dev Reverts with {InsufficientAvailableBalance} if trying to transfer more than available
     * @dev Only unlocked tokens can be transferred
     */
    function transfer(address to, uint256 value) external returns (bool success);
    
    /**
     * @notice Transfers tokens from one account to another using allowance
     * @param from The sender address
     * @param to The recipient address
     * @param value The amount of tokens to transfer
     * @return success True if the transfer was successful
     * @dev Reverts with {InsufficientAvailableBalance} if trying to transfer more than available
     * @dev Only unlocked tokens can be transferred
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
    
    /**
     * @notice Approves a spender to transfer tokens on behalf of the caller
     * @param spender The address to approve
     * @param value The amount of tokens to approve
     * @return success True if the approval was successful
     * @dev Reverts with {CannotApproveMoreThanAvailableBalance} if trying to approve more than available
     * @dev Only unlocked tokens can be approved for spending
     */
    function approve(address spender, uint256 value) external returns (bool success);
    
    // ============ Overridden TokenRemote Functions ============
    
    /**
     * @notice Sends tokens to another blockchain
     * @param input Specifies information for delivery of the tokens
     * @param amount Amount of tokens to send
     * @dev Reverts with {InsufficientAvailableBalance} if trying to send more than available
     * @dev Only unlocked tokens can be sent cross-chain
     */
    function send(SendTokensInput calldata input, uint256 amount) external;
    
    /**
     * @notice Sends tokens to another blockchain for use in a smart contract interaction
     * @param input Specifies information for delivery of the tokens
     * @param amount Amount of tokens to send
     * @dev Reverts with {InsufficientAvailableBalance} if trying to send more than available
     * @dev Only unlocked tokens can be sent cross-chain
     */
    function sendAndCall(SendAndCallInput calldata input, uint256 amount) external;
    
    // ============ Initialization Functions ============
    
    /**
     * @notice Initializes the ERC20 Token Remote contract
     * @param settings Constructor settings for this token remote instance
     * @param tokenName The name of the ERC20 token
     * @param tokenSymbol The symbol of the ERC20 token
     * @param tokenDecimals The number of decimals for the ERC20 token
     * @param forwarder The trusted forwarder address for gasless transactions
     */
    function initialize(
        TokenRemoteSettings memory settings,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        address forwarder
    ) external;
}
