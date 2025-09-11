// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.25;

import {Initializable} from '@openzeppelin/contracts-upgradeable@5.0.2/proxy/utils/Initializable.sol';
import {ContextUpgradeable} from '@openzeppelin/contracts-upgradeable@5.0.2/utils/ContextUpgradeable.sol';
import {IConfigs} from './interfaces/IConfigs.sol';
import {IAccessController} from './interfaces/IAccessController.sol';

/**
 * @title ConfigManagerUpgradeable
 * @notice Abstract contract providing configuration management functionality for upgradeable contracts.
 * @dev This contract provides a standardized way to manage configuration contracts and access control
 *      through the IConfigs and IAccessController interfaces. It includes role-based access control
 *      for configuration management operations.
 * @custom:security-contact https://github.com/ava-labs/icm-contracts/blob/main/SECURITY.md
 */
abstract contract ConfigManagerUpgradeable is Initializable, ContextUpgradeable {
  // ==================== Constants ====================

  /// @dev Role identifier for configuration managers
  bytes32 public constant CONFIG_MANAGER_ROLE = keccak256('CONFIG_MANAGER_ROLE');

  // ==================== State Variables ====================

  /// @dev The configuration contract that holds system-wide configuration
  IConfigs public configContract;

  // ==================== Errors ====================

  /// @notice Thrown when a zero address is provided where it's not allowed
  error ZeroAddress();

  /// @notice Thrown when a required contract or configuration doesn't exist
  error NotExists();

  /// @notice Thrown when a user doesn't have the required permissions
  error NotPermitted(address user);

  // ==================== Initialization ====================

  /**
   * @notice Initializes the configuration manager
   * @dev This function should be called during contract initialization
   * @param _configAddress The address of the configuration contract
   */
  function _initConfigManager(address _configAddress) internal {
    if (_configAddress == address(0)) revert ZeroAddress();
    configContract = IConfigs(_configAddress);
  }

  // ==================== Modifiers ====================

  /**
   * @notice Modifier to restrict access to configuration managers only
   * @dev Checks if the caller has the CONFIG_MANAGER_ROLE through the access controller
   */
  modifier onlyConfigManager() {
    address accessController = configContract.accessControllerAddress();
    if (accessController == address(0)) revert NotExists();

    if (!IAccessController(accessController).hasAdminRole(CONFIG_MANAGER_ROLE, _msgSender())) {
      revert NotPermitted(_msgSender());
    }
    _;
  }
}
