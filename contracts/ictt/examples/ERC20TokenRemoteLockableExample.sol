// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.25;

import {IERC20TokenRemoteLockable} from "../interfaces/IERC20TokenRemoteLockable.sol";

/**
 * @title ERC20TokenRemoteLockableExample
 * @notice Example contract demonstrating how to interact with the ERC20TokenRemoteLockable interface
 * @dev This is a simple example showing basic usage patterns
 */
contract ERC20TokenRemoteLockableExample {
    
    IERC20TokenRemoteLockable public token;
    
    constructor(address _token) {
        token = IERC20TokenRemoteLockable(_token);
    }
    
    /**
     * @notice Example function showing how to check locked and available amounts
     * @param account The account to check
     */
    function checkAccountStatus(address account) external view returns (
        uint256 balance,
        uint256 locked,
        uint256 available
    ) {
        balance = token.balanceOf(account);
        locked = token.getLockedAmount(account);
        available = token.getAvailableAmount(account);
    }
    
    /**
     * @notice Example function showing how to lock tokens for a user
     * @param amount The amount to lock
     */
    function lockUserTokens(uint256 amount) external {
        token.lockTokens(amount);
    }
    
    /**
     * @notice Example function showing how to unlock tokens for a user
     * @param amount The amount to unlock
     */
    function unlockUserTokens(uint256 amount) external {
        token.unlockTokens(amount);
    }
    
    /**
     * @notice Example function showing how to transfer only available tokens
     * @param to The recipient
     * @param amount The amount to transfer
     */
    function transferAvailableTokens(address to, uint256 amount) external {
        // Check if user has enough available tokens
        uint256 available = token.getAvailableAmount(msg.sender);
        require(available >= amount, "Not enough available tokens");
        
        // Transfer the tokens
        token.transfer(to, amount);
    }
    
    /**
     * @notice Example function showing how to approve only available tokens
     * @param spender The spender address
     * @param amount The amount to approve
     */
    function approveAvailableTokens(address spender, uint256 amount) external {
        // Check if user has enough available tokens
        uint256 available = token.getAvailableAmount(msg.sender);
        require(available >= amount, "Not enough available tokens");
        
        // Approve the tokens
        token.approve(spender, amount);
    }
    
    /**
     * @notice Example function showing how to handle errors gracefully
     * @param amount The amount to lock
     */
    function safeLockTokens(uint256 amount) external returns (bool success) {
        try token.lockTokens(amount) {
            success = true;
        } catch {
            // Handle any errors (including custom errors)
            // Note: Custom errors can be caught but not specifically typed in catch blocks
            success = false;
        }
    }
    
    /**
     * @notice Example function showing how to check for specific conditions before calling
     * @param amount The amount to lock
     */
    function safeLockTokensWithChecks(uint256 amount) external returns (bool success) {
        // Check conditions before calling to avoid errors
        if (amount == 0) {
            return false; // AmountMustBeGreaterThanZero error
        }
        
        if (token.balanceOf(msg.sender) < amount) {
            return false; // InsufficientBalanceToLock error
        }
        
        // Safe to call now
        token.lockTokens(amount);
        return true;
    }
}
