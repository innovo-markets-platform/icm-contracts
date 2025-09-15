// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// @title IConfigs
interface IConfigs {
  // Currency types enum
  enum CurrencyType {
    USDC, // USD Coin
    USDT // Tether USD
  }

  /// @dev Returns the access controller contract address
  function accessControllerAddress() external view returns (address);

  /// @dev Returns the erc20 Token locker contract address
  function erc20TokenLockerAddress(Constants.CurrencyType) external view returns (address);
}
