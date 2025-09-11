// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// @title IConfigs
interface IConfigs {
  /// @dev Returns the access controller contract address
  function accessControllerAddress() external view returns (address);

  /// @dev Returns the erc20 Token locker contract address
  function erc20TokenLockerAddress() external view returns (address);
}
