// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// @title ILockableERC20
/// @notice Interface for ERC-20 contracts that integrate with TokenLocker.
interface ILockableERC20 {
  event TokenLockerUpdated(address indexed oldLocker, address indexed newLocker);

  /// @notice Sets or updates the TokenLocker contract
  function setTokenLocker(address locker) external;

  /// @notice Returns the current TokenLocker contract
  function getTokenLocker() external view returns (address);
}
