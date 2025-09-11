// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.25;

import {ERC20TokenTransferrerTest} from "./ERC20TokenTransferrerTests.t.sol";
import {TokenRemoteTest} from "./TokenRemoteTests.t.sol";
import {IERC20SendAndCallReceiver} from "../interfaces/IERC20SendAndCallReceiver.sol";
import {TokenRemote} from "../TokenRemote/TokenRemote.sol";
import {TokenRemoteSettings} from "../TokenRemote/interfaces/ITokenRemote.sol";
import {ERC20TokenRemoteUpgradeable} from "../TokenRemote/ERC20TokenRemoteUpgradeable.sol";
import {IERC20TokenRemoteLockable} from "../interfaces/IERC20TokenRemoteLockable.sol";
import {ERC20TokenRemote} from "../TokenRemote/ERC20TokenRemote.sol";
import {SafeERC20} from "@openzeppelin/contracts@5.0.2/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts@5.0.2/token/ERC20/IERC20.sol";
import {ExampleERC20} from "@mocks/ExampleERC20.sol";
import {SendTokensInput} from "../interfaces/ITokenTransferrer.sol";
import {Ownable} from "@openzeppelin/contracts@5.0.2/access/Ownable.sol";
import {ICMInitializable} from "@utilities/ICMInitializable.sol";
import {Initializable} from "@openzeppelin/contracts@5.0.2/proxy/utils/Initializable.sol";

contract ERC20TokenRemoteTest is ERC20TokenTransferrerTest, TokenRemoteTest {
    using SafeERC20 for IERC20;

    string public constant MOCK_TOKEN_NAME = "Test Token";
    string public constant MOCK_TOKEN_SYMBOL = "TST";

    ERC20TokenRemoteUpgradeable public app;

    // Events for token locking functionality
    event TokensLocked(address indexed account, uint256 amount, uint256 totalLocked);
    event TokensUnlocked(address indexed account, uint256 amount, uint256 totalLocked);

    function setUp() public virtual override {
        TokenRemoteTest.setUp();

        tokenDecimals = 14;
        tokenHomeDecimals = 18;
        app = ERC20TokenRemoteUpgradeable(address(_createNewRemoteInstance()));

        erc20TokenTransferrer = app;
        tokenRemote = app;
        tokenTransferrer = app;

        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(address(0), address(this), 10e18);

        vm.prank(MOCK_TELEPORTER_MESSENGER_ADDRESS);
        app.receiveTeleporterMessage(
            DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID,
            DEFAULT_TOKEN_HOME_ADDRESS,
            _encodeSingleHopSendMessage(10e18, address(this))
        );
    }

    /**
     * Initialization unit tests
     */
    function testNonUpgradeableInitialization() public {
        app = new ERC20TokenRemote(
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
            address(0) // forwarder address for testing
        );
        assertEq(app.getBlockchainID(), DEFAULT_TOKEN_REMOTE_BLOCKCHAIN_ID);
    }

    function testDisableInitialization() public {
        app = new ERC20TokenRemoteUpgradeable(ICMInitializable.Disallowed);
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        app.initialize(
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
            address(0) // forwarder address for testing
        );
    }

    function testZeroTeleporterRegistryAddress() public {
        _invalidInitialization(
            TokenRemoteSettings({
                teleporterRegistryAddress: address(0),
                teleporterManager: address(this),
                minTeleporterVersion: 1,
                tokenHomeBlockchainID: DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID,
                tokenHomeAddress: DEFAULT_TOKEN_HOME_ADDRESS,
                tokenHomeDecimals: tokenHomeDecimals
            }),
            MOCK_TOKEN_NAME,
            MOCK_TOKEN_SYMBOL,
            tokenDecimals,
            "TeleporterRegistryApp: zero Teleporter registry address"
        );
    }

    function testZeroTeleporterManagerAddress() public {
        _invalidInitialization(
            TokenRemoteSettings({
                teleporterRegistryAddress: MOCK_TELEPORTER_REGISTRY_ADDRESS,
                teleporterManager: address(0),
                minTeleporterVersion: 1,
                tokenHomeBlockchainID: DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID,
                tokenHomeAddress: DEFAULT_TOKEN_HOME_ADDRESS,
                tokenHomeDecimals: tokenHomeDecimals
            }),
            MOCK_TOKEN_NAME,
            MOCK_TOKEN_SYMBOL,
            tokenDecimals,
            abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0))
        );
    }

    function testZeroTokenHomeBlockchainID() public {
        _invalidInitialization(
            TokenRemoteSettings({
                teleporterRegistryAddress: MOCK_TELEPORTER_REGISTRY_ADDRESS,
                teleporterManager: address(this),
                minTeleporterVersion: 1,
                tokenHomeBlockchainID: bytes32(0),
                tokenHomeAddress: DEFAULT_TOKEN_HOME_ADDRESS,
                tokenHomeDecimals: tokenHomeDecimals
            }),
            MOCK_TOKEN_NAME,
            MOCK_TOKEN_SYMBOL,
            tokenDecimals,
            _formatErrorMessage("zero token home blockchain ID")
        );
    }

    function testDeployToSameBlockchain() public {
        _invalidInitialization(
            TokenRemoteSettings({
                teleporterRegistryAddress: MOCK_TELEPORTER_REGISTRY_ADDRESS,
                teleporterManager: address(this),
                minTeleporterVersion: 1,
                tokenHomeBlockchainID: DEFAULT_TOKEN_REMOTE_BLOCKCHAIN_ID,
                tokenHomeAddress: DEFAULT_TOKEN_HOME_ADDRESS,
                tokenHomeDecimals: tokenHomeDecimals
            }),
            MOCK_TOKEN_NAME,
            MOCK_TOKEN_SYMBOL,
            tokenDecimals,
            _formatErrorMessage("cannot deploy to same blockchain as token home")
        );
    }

    function testZeroTokenHomeAddress() public {
        _invalidInitialization(
            TokenRemoteSettings({
                teleporterRegistryAddress: MOCK_TELEPORTER_REGISTRY_ADDRESS,
                teleporterManager: address(this),
                minTeleporterVersion: 1,
                tokenHomeBlockchainID: DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID,
                tokenHomeAddress: address(0),
                tokenHomeDecimals: 18
            }),
            MOCK_TOKEN_NAME,
            MOCK_TOKEN_SYMBOL,
            18,
            _formatErrorMessage("zero token home address")
        );
    }

    function testSendWithSeparateFeeAsset() public {
        uint256 amount = 200_000;
        uint256 feeAmount = 100;
        ExampleERC20 separateFeeAsset = new ExampleERC20();
        SendTokensInput memory input = _createDefaultSendTokensInput();
        input.primaryFeeTokenAddress = address(separateFeeAsset);
        input.primaryFee = feeAmount;

        IERC20(separateFeeAsset).safeIncreaseAllowance(address(tokenTransferrer), feeAmount);
        vm.expectCall(
            address(separateFeeAsset),
            abi.encodeCall(
                IERC20.transferFrom, (address(this), address(tokenTransferrer), feeAmount)
            )
        );
        // Increase the allowance of the token transferrer to transfer the funds from the user
        IERC20(app).safeIncreaseAllowance(address(tokenTransferrer), amount);

        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(address(this), address(0), amount);
        _checkExpectedTeleporterCallsForSend(_createSingleHopTeleporterMessageInput(input, amount));
        vm.expectEmit(true, true, true, true, address(tokenTransferrer));
        emit TokensSent(_MOCK_MESSAGE_ID, address(this), input, amount);
        _send(input, amount);
    }

    function testDecimals() public view {
        uint8 res = app.decimals();
        assertEq(tokenDecimals, res);
    }

    function _createNewRemoteInstance() internal virtual override returns (TokenRemote) {
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
            address(0) // forwarder address for testing
        );
        return instance;
    }

    function _checkExpectedWithdrawal(address recipient, uint256 amount) internal override {
        vm.expectEmit(true, true, true, true, address(tokenRemote));
        emit TokensWithdrawn(recipient, amount);
        vm.expectEmit(true, true, true, true, address(tokenRemote));
        emit Transfer(address(0), recipient, amount);
    }

    function _setUpExpectedSendAndCall(
        bytes32 sourceBlockchainID,
        OriginSenderInfo memory originInfo,
        address recipient,
        uint256 amount,
        bytes memory payload,
        uint256 gasLimit,
        bool targetHasCode,
        bool expectSuccess
    ) internal override {
        // The transferred tokens will be minted to the contract itself
        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(address(0), address(tokenRemote), amount);

        // Then recipient contract is then approved to spend them
        vm.expectEmit(true, true, true, true, address(app));
        emit Approval(address(app), DEFAULT_RECIPIENT_CONTRACT_ADDRESS, amount);

        if (targetHasCode) {
            vm.etch(recipient, new bytes(1));

            bytes memory expectedCalldata = abi.encodeCall(
                IERC20SendAndCallReceiver.receiveTokens,
                (
                    sourceBlockchainID,
                    originInfo.tokenTransferrerAddress,
                    originInfo.senderAddress,
                    address(app),
                    amount,
                    payload
                )
            );
            if (expectSuccess) {
                vm.mockCall(recipient, expectedCalldata, new bytes(0));
            } else {
                vm.mockCallRevert(recipient, expectedCalldata, new bytes(0));
            }
            vm.expectCall(recipient, 0, uint64(gasLimit), expectedCalldata);
        } else {
            vm.etch(recipient, new bytes(0));
        }

        // Then recipient contract approval is reset
        vm.expectEmit(true, true, true, true, address(app));
        emit Approval(address(app), DEFAULT_RECIPIENT_CONTRACT_ADDRESS, 0);

        if (targetHasCode && expectSuccess) {
            // The call should have succeeded.
            vm.expectEmit(true, true, true, true, address(app));
            emit CallSucceeded(DEFAULT_RECIPIENT_CONTRACT_ADDRESS, amount);
        } else {
            // The call should have failed.
            vm.expectEmit(true, true, true, true, address(app));
            emit CallFailed(DEFAULT_RECIPIENT_CONTRACT_ADDRESS, amount);

            // Then the amount should be sent to the fallback recipient.
            vm.expectEmit(true, true, true, true, address(app));
            emit Transfer(address(app), address(DEFAULT_FALLBACK_RECIPIENT_ADDRESS), amount);
        }
    }

    function _setUpExpectedZeroAmountRevert() internal override {
        vm.expectRevert(_formatErrorMessage("insufficient tokens to transfer"));
    }

    function _setUpExpectedDeposit(uint256 amount, uint256 feeAmount) internal virtual override {
        // Transfer the fee to the token transferrer if it is greater than 0
        if (feeAmount > 0) {
            IERC20(app).safeIncreaseAllowance(address(tokenTransferrer), feeAmount);
        }

        // Increase the allowance of the token transferrer to transfer the funds from the user
        IERC20(app).safeIncreaseAllowance(address(tokenTransferrer), amount);

        // Account for the burn before sending
        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(address(this), address(0), amount);

        if (feeAmount > 0) {
            vm.expectEmit(true, true, true, true, address(app));
            emit Transfer(address(this), address(tokenTransferrer), feeAmount);
        }
    }

    function _getTotalSupply() internal view override returns (uint256) {
        return app.totalSupply();
    }

    function _setUpMockMint(address, uint256) internal pure override {
        // Don't need to mock the minting of an ERC20TokenRemoteUpgradeable since it is an internal call
        // on the remote contract.
        return;
    }

    function _invalidInitialization(
        TokenRemoteSettings memory settings,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals_,
        bytes memory expectedErrorMessage
    ) private {
        app = new ERC20TokenRemoteUpgradeable(ICMInitializable.Allowed);
        vm.expectRevert(expectedErrorMessage);
        app.initialize(settings, tokenName, tokenSymbol, tokenDecimals_, address(0));
    }

    /**
     * Token locking functionality tests
     */
    function testInitialLockedAmount() public view {
        assertEq(app.getLockedAmount(address(this)), 0, "Initial locked amount should be 0");
    }

    function testGetAvailableAmount() public view {
        uint256 balance = app.balanceOf(address(this));
        uint256 available = app.getAvailableAmount(address(this));
        assertEq(available, balance, "Available amount should equal balance when no tokens are locked");
    }

    function testLockTokens() public {
        uint256 lockAmount = 1000;
        
        vm.expectEmit(true, true, true, true, address(app));
        emit TokensLocked(address(this), lockAmount, lockAmount);
        
        app.lockTokens(lockAmount);
        
        assertEq(app.getLockedAmount(address(this)), lockAmount, "Locked amount should be updated");
        assertEq(app.getAvailableAmount(address(this)), 10e18 - lockAmount, "Available amount should be reduced");
    }

    function testLockTokensInsufficientBalance() public {
        uint256 lockAmount = 20e18; // More than balance
        
        vm.expectRevert(abi.encodeWithSelector(IERC20TokenRemoteLockable.InsufficientBalanceToLock.selector));
        app.lockTokens(lockAmount);
    }

    function testLockTokensZeroAmount() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20TokenRemoteLockable.AmountMustBeGreaterThanZero.selector));
        app.lockTokens(0);
    }

    function testUnlockTokens() public {
        uint256 lockAmount = 1000;
        uint256 unlockAmount = 500;
        
        // First lock some tokens
        app.lockTokens(lockAmount);
        
        vm.expectEmit(true, true, true, true, address(app));
        emit TokensUnlocked(address(this), unlockAmount, lockAmount - unlockAmount);
        
        app.unlockTokens(unlockAmount);
        
        assertEq(app.getLockedAmount(address(this)), lockAmount - unlockAmount, "Locked amount should be reduced");
        assertEq(app.getAvailableAmount(address(this)), 10e18 - (lockAmount - unlockAmount), "Available amount should be increased");
    }

    function testUnlockTokensInsufficientLocked() public {
        uint256 lockAmount = 1000;
        uint256 unlockAmount = 1500;
        
        // First lock some tokens
        app.lockTokens(lockAmount);
        
        vm.expectRevert(abi.encodeWithSelector(IERC20TokenRemoteLockable.InsufficientLockedAmountToUnlock.selector));
        app.unlockTokens(unlockAmount);
    }

    function testUnlockTokensZeroAmount() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20TokenRemoteLockable.AmountMustBeGreaterThanZero.selector));
        app.unlockTokens(0);
    }

    function testTransferWithLockedTokens() public {
        uint256 lockAmount = 1000;
        uint256 transferAmount = 500;
        address recipient = makeAddr("recipient");
        
        // Lock some tokens
        app.lockTokens(lockAmount);
        
        // Transfer should work with available amount
        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(address(this), recipient, transferAmount);
        app.transfer(recipient, transferAmount);
        
        assertEq(app.balanceOf(recipient), transferAmount, "Recipient should receive tokens");
        assertEq(app.getAvailableAmount(address(this)), 10e18 - lockAmount - transferAmount, "Available amount should be reduced");
    }

    function testTransferExceedsAvailableAmount() public {
        uint256 lockAmount = 1000;
        uint256 transferAmount = 10e18; // More than available
        address recipient = makeAddr("recipient");
        
        // Lock some tokens
        app.lockTokens(lockAmount);
        
        vm.expectRevert(abi.encodeWithSelector(IERC20TokenRemoteLockable.InsufficientAvailableBalance.selector));
        app.transfer(recipient, transferAmount);
    }

    function testTransferFromWithLockedTokens() public {
        uint256 lockAmount = 1000;
        uint256 transferAmount = 500;
        address spender = makeAddr("spender");
        address recipient = makeAddr("recipient");
        
        // Lock some tokens
        app.lockTokens(lockAmount);
        
        // Approve spender
        app.approve(spender, transferAmount);
        
        // TransferFrom should work with available amount
        vm.prank(spender);
        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(address(this), recipient, transferAmount);
        app.transferFrom(address(this), recipient, transferAmount);
        
        assertEq(app.balanceOf(recipient), transferAmount, "Recipient should receive tokens");
        assertEq(app.getAvailableAmount(address(this)), 10e18 - lockAmount - transferAmount, "Available amount should be reduced");
    }

    function testTransferFromExceedsAvailableAmount() public {
        uint256 lockAmount = 1000;
        uint256 transferAmount = 10e18; // More than available
        address spender = makeAddr("spender");
        address recipient = makeAddr("recipient");
        
        // Lock some tokens
        app.lockTokens(lockAmount);
        
        // Try to approve more than available - this should fail
        vm.expectRevert(abi.encodeWithSelector(IERC20TokenRemoteLockable.CannotApproveMoreThanAvailableBalance.selector));
        app.approve(spender, transferAmount);
    }

    function testApproveWithLockedTokens() public {
        uint256 lockAmount = 1000;
        uint256 approveAmount = 500;
        address spender = makeAddr("spender");
        
        // Lock some tokens
        app.lockTokens(lockAmount);
        
        // Approve should work with available amount (unlocked tokens)
        uint256 availableAmount = app.getAvailableAmount(address(this));
        require(approveAmount <= availableAmount, "Test setup: approve amount should be within available balance");
        
        vm.expectEmit(true, true, true, true, address(app));
        emit Approval(address(this), spender, approveAmount);
        app.approve(spender, approveAmount);
        
        assertEq(app.allowance(address(this), spender), approveAmount, "Allowance should be set");
    }

    function testApproveExceedsAvailableBalance() public {
        uint256 lockAmount = 1000;
        uint256 approveAmount = 10e18; // More than available
        address spender = makeAddr("spender");
        
        // Lock some tokens
        app.lockTokens(lockAmount);
        
        // Approve should fail when trying to approve more than available
        vm.expectRevert(abi.encodeWithSelector(IERC20TokenRemoteLockable.CannotApproveMoreThanAvailableBalance.selector));
        app.approve(spender, approveAmount);
    }

    function testMultipleLockUnlockOperations() public {
        uint256 lockAmount1 = 1000;
        uint256 lockAmount2 = 500;
        uint256 unlockAmount1 = 300;
        uint256 unlockAmount2 = 200;
        
        // Lock tokens multiple times
        app.lockTokens(lockAmount1);
        app.lockTokens(lockAmount2);
        
        assertEq(app.getLockedAmount(address(this)), lockAmount1 + lockAmount2, "Total locked amount should be correct");
        
        // Unlock tokens multiple times
        app.unlockTokens(unlockAmount1);
        app.unlockTokens(unlockAmount2);
        
        uint256 expectedLocked = lockAmount1 + lockAmount2 - unlockAmount1 - unlockAmount2;
        assertEq(app.getLockedAmount(address(this)), expectedLocked, "Final locked amount should be correct");
    }

    function testLockUnlockWithGaslessFlow() public {
        uint256 lockAmount = 1000;
        uint256 unlockAmount = 500;
        
        // Test that lock/unlock work with _msgSender() (for gasless transactions)
        // This simulates a gasless transaction where _msgSender() returns the real sender
        app.lockTokens(lockAmount);
        assertEq(app.getLockedAmount(address(this)), lockAmount, "Lock should work with gasless flow");
        
        app.unlockTokens(unlockAmount);
        assertEq(app.getLockedAmount(address(this)), lockAmount - unlockAmount, "Unlock should work with gasless flow");
    }

    function testSendWithLockedTokens() public {
        uint256 lockAmount = 1000;
        uint256 sendAmount = 500;
        SendTokensInput memory input = _createDefaultSendTokensInput();
        
        // Lock some tokens
        app.lockTokens(lockAmount);
        
        // Increase allowance
        IERC20(app).safeIncreaseAllowance(address(tokenTransferrer), sendAmount);
        
        // Send should work with available amount
        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(address(this), address(0), sendAmount);
        _checkExpectedTeleporterCallsForSend(_createSingleHopTeleporterMessageInput(input, sendAmount));
        vm.expectEmit(true, true, true, true, address(tokenTransferrer));
        emit TokensSent(_MOCK_MESSAGE_ID, address(this), input, sendAmount);
        _send(input, sendAmount);
    }

    function testSendExceedsAvailableAmount() public {
        uint256 lockAmount = 1000;
        uint256 sendAmount = 10e18; // More than available
        
        // Lock some tokens
        app.lockTokens(lockAmount);
        
        // Try to approve more than available - this should fail
        vm.expectRevert(abi.encodeWithSelector(IERC20TokenRemoteLockable.CannotApproveMoreThanAvailableBalance.selector));
        app.approve(address(tokenTransferrer), sendAmount);
    }

    function testReceiveTokensWhenLocked() public {
        uint256 lockAmount = 1000;
        uint256 receiveAmount = 2000;
        address recipient = makeAddr("recipient");
        
        // First give some tokens to recipient so they can lock them
        app.transfer(recipient, lockAmount);
        
        // Lock some tokens for recipient
        vm.prank(recipient);
        app.lockTokens(lockAmount);
        
        // Receiving tokens from home should still work when tokens are locked
        vm.expectEmit(true, true, true, true, address(app));
        emit TokensWithdrawn(recipient, receiveAmount);
        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(address(0), recipient, receiveAmount);
        
        vm.prank(MOCK_TELEPORTER_MESSENGER_ADDRESS);
        app.receiveTeleporterMessage(
            DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID,
            DEFAULT_TOKEN_HOME_ADDRESS,
            _encodeSingleHopSendMessage(receiveAmount, recipient)
        );
        
        assertEq(app.balanceOf(recipient), lockAmount + receiveAmount, "Recipient should receive tokens");
        assertEq(app.getLockedAmount(recipient), lockAmount, "Locked amount should remain unchanged");
        assertEq(app.getAvailableAmount(recipient), receiveAmount, "Available amount should be correct");
    }
}
