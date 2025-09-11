// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// @title ITokenLockerERC20
/// @notice Interface for managing partial locking of ERC-20 token balances with multiple authorized lockers and admin override capability.
interface ITokenLockerERC20 {
  // ==================== Events ====================

  /// @dev Emitted when tokens are locked for a user by a locker contract.
  event TokensLocked(address indexed locker, address indexed user, uint256 amount);

  /// @dev Emitted when tokens are unlocked for a user by a locker contract.
  event TokensUnlocked(address indexed locker, address indexed user);

  /// @dev Emitted when tokens are admin locked by the lock manager or owner.
  event TokensAdminLocked(address indexed admin, address indexed user, uint256 amount);

  /// @dev Emitted when tokens are admin unlocked by the lock manager or owner.
  event TokensAdminUnlocked(address indexed admin, address indexed user);

  // ==================== Locking ====================

  /// @notice Locks a specific amount of tokens for a user.
  /// @dev Callable only by authorized locker contracts.
  function lock(address user, uint256 amount) external;

  /// @notice Unlocks all tokens locked for a user by the calling locker contract.
  /// @dev Callable only by authorized locker contracts.
  function unlockAll(address user) external;

  /// @notice Unlocks specified amount of tokens locked for a user by the calling locker contract.
  /// @dev Callable only by authorized locker contracts.
  function unlock(address user, uint256 amount) external;

  /// @notice Locks tokens for a user via admin authority.
  /// @dev Callable by the lock manager or contract owner.
  function adminLock(address user, uint256 amount) external;

  /// @notice Unlocks all tokens for a user previously locked by a specific locker or admin.
  /// @dev Callable by the lock manager or contract owner.
  function adminUnlockAll(address locker, address user) external;

  /// @notice Unlocks specified amount of tokens for a user previously locked by a specific locker or admin.
  /// @dev Callable by the lock manager or contract owner.
  function adminUnlock(address locker, address user, uint256 amount) external;

  // ==================== Views ====================

  /// @notice Returns the locked amount for a user locked by a specific locker.
  function getLockedAmountByLocker(address locker, address user) external view returns (uint256);

  /// @notice Returns the total locked amount for a user across all lockers.
  function getTotalLockedAmount(address user) external view returns (uint256);
}
