// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.25;

import {ERC20TokenRemoteTest} from "./ERC20TokenRemoteTests.t.sol";
import {ERC20TokenRemoteUpgradeable} from "../TokenRemote/ERC20TokenRemoteUpgradeable.sol";
import {IERC20TokenRemoteLockable} from "../interfaces/IERC20TokenRemoteLockable.sol";
import {TokenRemote} from "../TokenRemote/TokenRemote.sol";
import {TokenRemoteSettings} from "../TokenRemote/interfaces/ITokenRemote.sol";
import {SendTokensInput} from "../interfaces/ITokenTransferrer.sol";
import {IERC20} from "@openzeppelin/contracts@5.0.2/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts@5.0.2/token/ERC20/utils/SafeERC20.sol";
import {ICMInitializable} from "@utilities/ICMInitializable.sol";

/**
 * @title ERC20TokenRemoteGaslessLockableTest
 * @notice Comprehensive tests for ERC20TokenRemote lockable functionality with gasless transactions
 * @custom:security-contact https://github.com/ava-labs/icm-contracts/blob/main/SECURITY.md
 */
contract ERC20TokenRemoteGaslessLockableTest is ERC20TokenRemoteTest {
    using SafeERC20 for IERC20;

    // Mock forwarder address for gasless testing
    address public constant MOCK_FORWARDER = address(0x1234567890123456789012345678901234567890);


    function setUp() public virtual override {
        ERC20TokenRemoteTest.setUp();
    }

    function _createNewRemoteInstance() internal override returns (TokenRemote) {
        ERC20TokenRemoteUpgradeable instance =
            new ERC20TokenRemoteUpgradeable(ICMInitializable.Allowed);
        instance.initialize(
            TokenRemoteSettings({
                teleporterRegistryAddress: MOCK_TELEPORTER_REGISTRY_ADDRESS,
                teleporterManager: address(this),
                minTeleporterVersion: 1,
                tokenHomeBlockchainID: DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID,
                tokenHomeAddress: DEFAULT_TOKEN_HOME_ADDRESS,
                tokenHomeDecimals: tokenHomeDecimals
            }),
            MOCK_TOKEN_NAME,
            MOCK_TOKEN_SYMBOL,
            tokenDecimals,
            MOCK_FORWARDER // forwarder address for gasless testing
        );
        return instance;
    }

    /**
     * Gasless lock/unlock functionality tests
     */
    function testGaslessLockTokens() public {
        uint256 lockAmount = 1000;
        address gaslessUser = makeAddr("gaslessUser");
        
        // Give tokens to the gasless user
        app.transfer(gaslessUser, lockAmount);
        
        // Test that lockTokens works with _msgSender() (which is used in gasless transactions)
        vm.prank(gaslessUser);
        vm.expectEmit(true, true, true, true, address(app));
        emit TokensLocked(gaslessUser, lockAmount, lockAmount);
        app.lockTokens(lockAmount);
        
        assertEq(app.getLockedAmount(gaslessUser), lockAmount, "Gasless user should have locked tokens");
    }

    function testGaslessUnlockTokens() public {
        uint256 lockAmount = 1000;
        uint256 unlockAmount = 500;
        address gaslessUser = makeAddr("gaslessUser");
        
        // Give tokens to the gasless user and lock them
        app.transfer(gaslessUser, lockAmount);
        vm.prank(gaslessUser);
        app.lockTokens(lockAmount);
        
        // Test that unlockTokens works with _msgSender() (which is used in gasless transactions)
        vm.prank(gaslessUser);
        vm.expectEmit(true, true, true, true, address(app));
        emit TokensUnlocked(gaslessUser, unlockAmount, lockAmount - unlockAmount);
        app.unlockTokens(unlockAmount);
        
        assertEq(app.getLockedAmount(gaslessUser), lockAmount - unlockAmount, "Gasless user should have partially unlocked tokens");
    }

    function testGaslessTransferWithLockedTokens() public {
        uint256 lockAmount = 1000;
        uint256 transferAmount = 500;
        address gaslessUser = makeAddr("gaslessUser");
        address recipient = makeAddr("recipient");
        
        // Give tokens to the gasless user and lock some
        app.transfer(gaslessUser, lockAmount + transferAmount);
        vm.prank(gaslessUser);
        app.lockTokens(lockAmount);
        
        // Test that transfer works with _msgSender() (which is used in gasless transactions)
        vm.prank(gaslessUser);
        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(gaslessUser, recipient, transferAmount);
        app.transfer(recipient, transferAmount);
        
        assertEq(app.balanceOf(recipient), transferAmount, "Recipient should receive tokens from gasless transfer");
        assertEq(app.getAvailableAmount(gaslessUser), 0, "Gasless user should have no available tokens");
    }

    function testGaslessTransferExceedsAvailable() public {
        uint256 lockAmount = 1000;
        uint256 transferAmount = 1000; // Same as locked amount, should fail
        address gaslessUser = makeAddr("gaslessUser");
        address recipient = makeAddr("recipient");
        
        // Give tokens to the gasless user and lock all of them
        app.transfer(gaslessUser, lockAmount);
        vm.prank(gaslessUser);
        app.lockTokens(lockAmount);
        
        // Test gasless transfer that should fail
        vm.prank(gaslessUser);
        vm.expectRevert(abi.encodeWithSelector(IERC20TokenRemoteLockable.InsufficientAvailableBalance.selector));
        app.transfer(recipient, transferAmount);
    }

    function testGaslessSendWithLockedTokens() public {
        uint256 lockAmount = 1000;
        uint256 sendAmount = 500;
        address gaslessUser = makeAddr("gaslessUser");
        SendTokensInput memory input = _createDefaultSendTokensInput();
        
        // Give tokens to the gasless user and lock some
        app.transfer(gaslessUser, lockAmount + sendAmount);
        vm.prank(gaslessUser);
        app.lockTokens(lockAmount);
        
        // Approve the contract to spend tokens
        vm.prank(gaslessUser);
        app.approve(address(tokenTransferrer), sendAmount);
        
        // Test gasless send
        vm.prank(gaslessUser);
        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(gaslessUser, address(0), sendAmount);
        _checkExpectedTeleporterCallsForSend(_createSingleHopTeleporterMessageInput(input, sendAmount));
        vm.expectEmit(true, true, true, true, address(tokenTransferrer));
        emit TokensSent(_MOCK_MESSAGE_ID, gaslessUser, input, sendAmount);
        app.send(input, sendAmount);
    }

    function testGaslessSendExceedsAvailable() public {
        uint256 lockAmount = 1000;
        uint256 sendAmount = 1000; // Same as locked amount, should fail
        address gaslessUser = makeAddr("gaslessUser");
        
        // Give tokens to the gasless user and lock all of them
        app.transfer(gaslessUser, lockAmount);
        vm.prank(gaslessUser);
        app.lockTokens(lockAmount);
        
        // Try to approve more than available - this should fail
        vm.prank(gaslessUser);
        vm.expectRevert(abi.encodeWithSelector(IERC20TokenRemoteLockable.CannotApproveMoreThanAvailableBalance.selector));
        app.approve(address(tokenTransferrer), sendAmount);
    }

    function testGaslessApproveWithLockedTokens() public {
        uint256 lockAmount = 1000;
        uint256 approveAmount = 500;
        address gaslessUser = makeAddr("gaslessUser");
        address spender = makeAddr("spender");
        
        // Give tokens to the gasless user and lock some
        app.transfer(gaslessUser, lockAmount + approveAmount);
        vm.prank(gaslessUser);
        app.lockTokens(lockAmount);
        
        // Test that approve works with available amount (unlocked tokens)
        vm.prank(gaslessUser);
        vm.expectEmit(true, true, true, true, address(app));
        emit Approval(gaslessUser, spender, approveAmount);
        app.approve(spender, approveAmount);
        
        assertEq(app.allowance(gaslessUser, spender), approveAmount, "Gasless user should be able to approve available tokens");
    }

    function testGaslessTransferFromWithLockedTokens() public {
        uint256 lockAmount = 1000;
        uint256 transferAmount = 500;
        address gaslessUser = makeAddr("gaslessUser");
        address spender = makeAddr("spender");
        address recipient = makeAddr("recipient");
        
        // Give tokens to the gasless user and lock some
        app.transfer(gaslessUser, lockAmount + transferAmount);
        vm.prank(gaslessUser);
        app.lockTokens(lockAmount);
        
        // Approve spender
        vm.prank(gaslessUser);
        app.approve(spender, transferAmount);
        
        // Test gasless transferFrom
        vm.prank(spender);
        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(gaslessUser, recipient, transferAmount);
        app.transferFrom(gaslessUser, recipient, transferAmount);
        
        assertEq(app.balanceOf(recipient), transferAmount, "Recipient should receive tokens from gasless transferFrom");
        assertEq(app.getAvailableAmount(gaslessUser), 0, "Gasless user should have no available tokens");
    }

    function testGaslessTransferFromExceedsAvailable() public {
        uint256 lockAmount = 1000;
        uint256 transferAmount = 1000; // Same as locked amount, should fail
        address gaslessUser = makeAddr("gaslessUser");
        address spender = makeAddr("spender");
        
        // Give tokens to the gasless user and lock all of them
        app.transfer(gaslessUser, lockAmount);
        vm.prank(gaslessUser);
        app.lockTokens(lockAmount);
        
        // Try to approve more than available - this should fail
        vm.prank(gaslessUser);
        vm.expectRevert(abi.encodeWithSelector(IERC20TokenRemoteLockable.CannotApproveMoreThanAvailableBalance.selector));
        app.approve(spender, transferAmount);
    }

    function testGaslessMultipleLockUnlockOperations() public {
        uint256 lockAmount1 = 1000;
        uint256 lockAmount2 = 500;
        uint256 unlockAmount1 = 300;
        uint256 unlockAmount2 = 200;
        address gaslessUser = makeAddr("gaslessUser");
        
        // Give tokens to the gasless user
        app.transfer(gaslessUser, lockAmount1 + lockAmount2);
        
        // Test gasless multiple lock operations
        vm.prank(gaslessUser);
        app.lockTokens(lockAmount1);
        
        vm.prank(gaslessUser);
        app.lockTokens(lockAmount2);
        
        assertEq(app.getLockedAmount(gaslessUser), lockAmount1 + lockAmount2, "Total locked amount should be correct");
        
        // Test gasless multiple unlock operations
        vm.prank(gaslessUser);
        app.unlockTokens(unlockAmount1);
        
        vm.prank(gaslessUser);
        app.unlockTokens(unlockAmount2);
        
        uint256 expectedLocked = lockAmount1 + lockAmount2 - unlockAmount1 - unlockAmount2;
        assertEq(app.getLockedAmount(gaslessUser), expectedLocked, "Final locked amount should be correct");
    }

    function testGaslessReceiveTokensWhenLocked() public {
        uint256 lockAmount = 1000;
        uint256 receiveAmount = 2000;
        address gaslessUser = makeAddr("gaslessUser");
        
        // Give some tokens to the gasless user and lock them
        app.transfer(gaslessUser, lockAmount);
        vm.prank(gaslessUser);
        app.lockTokens(lockAmount);
        
        // Mock gasless receive tokens from home
        vm.prank(MOCK_TELEPORTER_MESSENGER_ADDRESS);
        vm.expectEmit(true, true, true, true, address(app));
        emit TokensWithdrawn(gaslessUser, receiveAmount);
        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(address(0), gaslessUser, receiveAmount);
        app.receiveTeleporterMessage(
            DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID,
            DEFAULT_TOKEN_HOME_ADDRESS,
            _encodeSingleHopSendMessage(receiveAmount, gaslessUser)
        );
        
        assertEq(app.balanceOf(gaslessUser), lockAmount + receiveAmount, "Gasless user should receive tokens");
        assertEq(app.getLockedAmount(gaslessUser), lockAmount, "Locked amount should remain unchanged");
        assertEq(app.getAvailableAmount(gaslessUser), receiveAmount, "Available amount should be correct");
    }

    function testGaslessLockUnlockEdgeCases() public {
        address gaslessUser = makeAddr("gaslessUser");
        
        // Test locking all available tokens
        uint256 totalBalance = 10e18;
        app.transfer(gaslessUser, totalBalance);
        
        vm.prank(gaslessUser);
        app.lockTokens(totalBalance);
        
        assertEq(app.getLockedAmount(gaslessUser), totalBalance, "Should be able to lock all tokens");
        assertEq(app.getAvailableAmount(gaslessUser), 0, "Available amount should be 0");
        
        // Test unlocking all tokens
        vm.prank(gaslessUser);
        app.unlockTokens(totalBalance);
        
        assertEq(app.getLockedAmount(gaslessUser), 0, "Should be able to unlock all tokens");
        assertEq(app.getAvailableAmount(gaslessUser), totalBalance, "Available amount should equal balance");
    }
}
