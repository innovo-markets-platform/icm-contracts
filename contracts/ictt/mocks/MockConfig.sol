// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.25;

import {IConfigs} from '../TokenRemote/interfaces/IConfigs.sol';

/**
 * @title MockConfig
 * @notice Mock implementation of IConfigs for testing purposes
 * @dev This contract provides a simple mock implementation that returns zero addresses
 *      for all config values, suitable for testing scenarios where config contracts
 *      are not needed or should be disabled.
 * @custom:security-contact https://github.com/ava-labs/icm-contracts/blob/main/SECURITY.md
 */
contract MockConfig is IConfigs {
    /// @dev Returns the access controller contract address (always zero for mock)
    function accessControllerAddress() external pure override returns (address) {
        return address(0);
    }

    /// @dev Returns the erc20 Token locker contract address (always zero for mock)
    function erc20TokenLockerAddress(IConfigs.CurrencyType currency) external pure override returns (address) {
        return address(0);
    }
}
