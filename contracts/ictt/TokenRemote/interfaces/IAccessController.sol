// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// @title IAccessController
/// @notice Interface for the AccessController (Upgradeable) contract
/// @dev Provides two-layer role-based access control:
///      - Admin roles: managed by contract owner (multisig/governance)
///      - Transactional roles: managed by designated admin(s)
///      - SuperAdmin: can recover ownership in case of a breach
///      Designed for use with OpenZeppelin upgradeable proxies.
interface IAccessController {
  // ============ Errors ============
  /// @notice Thrown when attempting to use address(0)
  error ZeroAddress();

  /// @notice Thrown when assigning a role that an account already has
  error RoleAlreadyAssigned(bytes32 role, address account);

  /// @notice Thrown when trying to use/revoke a role that an account does not have
  error RoleNotAssigned(bytes32 role, address account);

  // ============ Events ============
  /// @notice Emitted when a transactional role is granted
  /// @param role The role identifier
  /// @param account The account that received the role
  /// @param grantedBy The admin who granted the role
  event TransactionalRoleGranted(bytes32 indexed role, address indexed account, address indexed grantedBy);

  /// @notice Emitted when a transactional role is revoked
  /// @param role The role identifier
  /// @param account The account that lost the role
  /// @param revokedBy The admin who revoked the role
  event TransactionalRoleRevoked(bytes32 indexed role, address indexed account, address indexed revokedBy);

  /// @notice Emitted when an admin role is granted
  /// @param role The role identifier
  /// @param account The account that received the role
  /// @param grantedBy The owner who granted the role
  event AdminRoleGranted(bytes32 indexed role, address indexed account, address indexed grantedBy);

  /// @notice Emitted when an admin role is revoked
  /// @param role The role identifier
  /// @param account The account that lost the role
  /// @param revokedBy The owner who revoked the role
  event AdminRoleRevoked(bytes32 indexed role, address indexed account, address indexed revokedBy);

  /// @notice Emitted when ownership is recovered by a SuperAdmin
  /// @param oldOwner The previous owner
  /// @param newOwner The new owner (multisig/governance)
  /// @param triggeredBy The SuperAdmin who triggered the recovery
  event OwnershipRecovered(address indexed oldOwner, address indexed newOwner, address indexed triggeredBy);

  // ============ Initializer ============
  /// @notice Initializes the upgradeable contract
  /// @param ownerAddress The initial owner (multisig/governance)
  function initialize(address ownerAddress) external;

  // ============ Admin Role Management ============
  /// @notice Grants an admin role to an account
  /// @param role The role identifier
  /// @param account The account to grant the role to
  function grantAdminRole(bytes32 role, address account) external;

  /// @notice Revokes an admin role from an account
  /// @param role The role identifier
  /// @param account The account to revoke the role from
  function revokeAdminRole(bytes32 role, address account) external;

  /// @notice Checks if an account has a given admin role
  /// @param role The role identifier
  /// @param account The account to check
  /// @return True if the account has the role, false otherwise
  function hasAdminRole(bytes32 role, address account) external view returns (bool);

  // ============ Transactional Role Management ============
  /// @notice Grants a transactional role to an account
  /// @param role The role identifier
  /// @param account The account to grant the role to
  function grantTransactionalRole(bytes32 role, address account) external;

  /// @notice Revokes a transactional role from an account
  /// @param role The role identifier
  /// @param account The account to revoke the role from
  function revokeTransactionalRole(bytes32 role, address account) external;

  /// @notice Checks if an account has a given transactional role
  /// @param role The role identifier
  /// @param account The account to check
  /// @return True if the account has the role, false otherwise
  function hasTransactionalRole(bytes32 role, address account) external view returns (bool);

  // ============ SuperAdmin Recovery ============
  /// @notice Allows a SuperAdmin to recover ownership in case of breach
  /// @param newOwner The new owner address (multisig/governance)
  function recoverOwnership(address newOwner) external;
}
