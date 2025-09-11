// Sources flattened with hardhat v2.26.3 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (proxy/utils/Initializable.sol)

pragma solidity 0.8.25;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
  /**
   * @dev Storage of the initializable contract.
   *
   * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
   * when using with upgradeable contracts.
   *
   * @custom:storage-location erc7201:openzeppelin.storage.Initializable
   */
  struct InitializableStorage {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint64 _initialized;
    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool _initializing;
  }

  // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

  /**
   * @dev The contract is already initialized.
   */
  error InvalidInitialization();

  /**
   * @dev The contract is not initializing.
   */
  error NotInitializing();

  /**
   * @dev Triggered when the contract has been initialized or reinitialized.
   */
  event Initialized(uint64 version);

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
   * `onlyInitializing` functions can be used to initialize parent contracts.
   *
   * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
   * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
   * production.
   *
   * Emits an {Initialized} event.
   */
  modifier initializer() {
    // solhint-disable-next-line var-name-mixedcase
    InitializableStorage storage $ = _getInitializableStorage();

    // Cache values to avoid duplicated sloads
    bool isTopLevelCall = !$._initializing;
    uint64 initialized = $._initialized;

    // Allowed calls:
    // - initialSetup: the contract is not in the initializing state and no previous version was
    //                 initialized
    // - construction: the contract is initialized at version 1 (no reinitialization) and the
    //                 current contract is just being deployed
    bool initialSetup = initialized == 0 && isTopLevelCall;
    bool construction = initialized == 1 && address(this).code.length == 0;

    if (!initialSetup && !construction) {
      revert InvalidInitialization();
    }
    $._initialized = 1;
    if (isTopLevelCall) {
      $._initializing = true;
    }
    _;
    if (isTopLevelCall) {
      $._initializing = false;
      emit Initialized(1);
    }
  }

  /**
   * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
   * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
   * used to initialize parent contracts.
   *
   * A reinitializer may be used after the original initialization step. This is essential to configure modules that
   * are added through upgrades and that require initialization.
   *
   * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
   * cannot be nested. If one is invoked in the context of another, execution will revert.
   *
   * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
   * a contract, executing them in the right order is up to the developer or operator.
   *
   * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
   *
   * Emits an {Initialized} event.
   */
  modifier reinitializer(uint64 version) {
    // solhint-disable-next-line var-name-mixedcase
    InitializableStorage storage $ = _getInitializableStorage();

    if ($._initializing || $._initialized >= version) {
      revert InvalidInitialization();
    }
    $._initialized = version;
    $._initializing = true;
    _;
    $._initializing = false;
    emit Initialized(version);
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
   * {initializer} and {reinitializer} modifiers, directly or indirectly.
   */
  modifier onlyInitializing() {
    _checkInitializing();
    _;
  }

  /**
   * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
   */
  function _checkInitializing() internal view virtual {
    if (!_isInitializing()) {
      revert NotInitializing();
    }
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
   * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
   * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
   * through proxies.
   *
   * Emits an {Initialized} event the first time it is successfully executed.
   */
  function _disableInitializers() internal virtual {
    // solhint-disable-next-line var-name-mixedcase
    InitializableStorage storage $ = _getInitializableStorage();

    if ($._initializing) {
      revert InvalidInitialization();
    }
    if ($._initialized != type(uint64).max) {
      $._initialized = type(uint64).max;
      emit Initialized(type(uint64).max);
    }
  }

  /**
   * @dev Returns the highest version that has been initialized. See {reinitializer}.
   */
  function _getInitializedVersion() internal view returns (uint64) {
    return _getInitializableStorage()._initialized;
  }

  /**
   * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
   */
  function _isInitializing() internal view returns (bool) {
    return _getInitializableStorage()._initializing;
  }

  /**
   * @dev Pointer to storage slot. Allows integrators to override it with a custom storage location.
   *
   * NOTE: Consider following the ERC-7201 formula to derive storage locations.
   */
  function _initializableStorageSlot() internal pure virtual returns (bytes32) {
    return INITIALIZABLE_STORAGE;
  }

  /**
   * @dev Returns a pointer to the storage namespace.
   */
  // solhint-disable-next-line var-name-mixedcase
  function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
    bytes32 slot = _initializableStorageSlot();
    assembly {
      $.slot := slot
    }
  }
}

// File @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
  function __Context_init() internal onlyInitializing {}

  function __Context_init_unchained() internal onlyInitializing {}
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }

  function _contextSuffixLength() internal view virtual returns (uint256) {
    return 0;
  }
}

// File @openzeppelin/contracts/utils/introspection/IERC165.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File @openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC-165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165Upgradeable is Initializable, IERC165 {
  function __ERC165_init() internal onlyInitializing {}

  function __ERC165_init_unchained() internal onlyInitializing {}
  /// @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

// File @openzeppelin/contracts/access/IAccessControl.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (access/IAccessControl.sol)

/**
 * @dev External interface of AccessControl declared to support ERC-165 detection.
 */
interface IAccessControl {
  /**
   * @dev The `account` is missing a role.
   */
  error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

  /**
   * @dev The caller of a function is not the expected one.
   *
   * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
   */
  error AccessControlBadConfirmation();

  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted to signal this.
   */
  event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call. This account bears the admin role (for the granted role).
   * Expected in cases where the role was granted using the internal {AccessControl-_grantRole}.
   */
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {AccessControl-_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been granted `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `callerConfirmation`.
   */
  function renounceRole(bytes32 role, address callerConfirmation) external;
}

// File @openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (access/AccessControl.sol)

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControl, ERC165Upgradeable {
  struct RoleData {
    mapping(address account => bool) hasRole;
    bytes32 adminRole;
  }

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  /// @custom:storage-location erc7201:openzeppelin.storage.AccessControl
  struct AccessControlStorage {
    mapping(bytes32 role => RoleData) _roles;
  }

  // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControl")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant AccessControlStorageLocation =
    0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800;

  function _getAccessControlStorage() private pure returns (AccessControlStorage storage $) {
    assembly {
      $.slot := AccessControlStorageLocation
    }
  }

  /**
   * @dev Modifier that checks that an account has a specific role. Reverts
   * with an {AccessControlUnauthorizedAccount} error including the required role.
   */
  modifier onlyRole(bytes32 role) {
    _checkRole(role);
    _;
  }

  function __AccessControl_init() internal onlyInitializing {}

  function __AccessControl_init_unchained() internal onlyInitializing {}
  /// @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) public view virtual returns (bool) {
    AccessControlStorage storage $ = _getAccessControlStorage();
    return $._roles[role].hasRole[account];
  }

  /**
   * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
   * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
   */
  function _checkRole(bytes32 role) internal view virtual {
    _checkRole(role, _msgSender());
  }

  /**
   * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
   * is missing `role`.
   */
  function _checkRole(bytes32 role, address account) internal view virtual {
    if (!hasRole(role, account)) {
      revert AccessControlUnauthorizedAccount(account, role);
    }
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
    AccessControlStorage storage $ = _getAccessControlStorage();
    return $._roles[role].adminRole;
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   *
   * May emit a {RoleGranted} event.
   */
  function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
    _grantRole(role, account);
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   *
   * May emit a {RoleRevoked} event.
   */
  function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
    _revokeRole(role, account);
  }

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been revoked `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `callerConfirmation`.
   *
   * May emit a {RoleRevoked} event.
   */
  function renounceRole(bytes32 role, address callerConfirmation) public virtual {
    if (callerConfirmation != _msgSender()) {
      revert AccessControlBadConfirmation();
    }

    _revokeRole(role, callerConfirmation);
  }

  /**
   * @dev Sets `adminRole` as ``role``'s admin role.
   *
   * Emits a {RoleAdminChanged} event.
   */
  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    AccessControlStorage storage $ = _getAccessControlStorage();
    bytes32 previousAdminRole = getRoleAdmin(role);
    $._roles[role].adminRole = adminRole;
    emit RoleAdminChanged(role, previousAdminRole, adminRole);
  }

  /**
   * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
   *
   * Internal function without access restriction.
   *
   * May emit a {RoleGranted} event.
   */
  function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
    AccessControlStorage storage $ = _getAccessControlStorage();
    if (!hasRole(role, account)) {
      $._roles[role].hasRole[account] = true;
      emit RoleGranted(role, account, _msgSender());
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Attempts to revoke `role` from `account` and returns a boolean indicating if `role` was revoked.
   *
   * Internal function without access restriction.
   *
   * May emit a {RoleRevoked} event.
   */
  function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
    AccessControlStorage storage $ = _getAccessControlStorage();
    if (hasRole(role, account)) {
      $._roles[role].hasRole[account] = false;
      emit RoleRevoked(role, account, _msgSender());
      return true;
    } else {
      return false;
    }
  }
}

// File @openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (utils/Pausable.sol)

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
  /// @custom:storage-location erc7201:openzeppelin.storage.Pausable
  struct PausableStorage {
    bool _paused;
  }

  // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Pausable")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant PausableStorageLocation = 0xcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f03300;

  function _getPausableStorage() private pure returns (PausableStorage storage $) {
    assembly {
      $.slot := PausableStorageLocation
    }
  }

  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  /**
   * @dev The operation failed because the contract is paused.
   */
  error EnforcedPause();

  /**
   * @dev The operation failed because the contract is not paused.
   */
  error ExpectedPause();

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    _requireNotPaused();
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    _requirePaused();
    _;
  }

  function __Pausable_init() internal onlyInitializing {}

  function __Pausable_init_unchained() internal onlyInitializing {}
  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view virtual returns (bool) {
    PausableStorage storage $ = _getPausableStorage();
    return $._paused;
  }

  /**
   * @dev Throws if the contract is paused.
   */
  function _requireNotPaused() internal view virtual {
    if (paused()) {
      revert EnforcedPause();
    }
  }

  /**
   * @dev Throws if the contract is not paused.
   */
  function _requirePaused() internal view virtual {
    if (!paused()) {
      revert ExpectedPause();
    }
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function _pause() internal virtual whenNotPaused {
    PausableStorage storage $ = _getPausableStorage();
    $._paused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function _unpause() internal virtual whenPaused {
    PausableStorage storage $ = _getPausableStorage();
    $._paused = false;
    emit Unpaused(_msgSender());
  }
}

// File @openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant NOT_ENTERED = 1;
  uint256 private constant ENTERED = 2;

  /// @custom:storage-location erc7201:openzeppelin.storage.ReentrancyGuard
  struct ReentrancyGuardStorage {
    uint256 _status;
  }

  // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant ReentrancyGuardStorageLocation =
    0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

  function _getReentrancyGuardStorage() private pure returns (ReentrancyGuardStorage storage $) {
    assembly {
      $.slot := ReentrancyGuardStorageLocation
    }
  }

  /**
   * @dev Unauthorized reentrant call.
   */
  error ReentrancyGuardReentrantCall();

  function __ReentrancyGuard_init() internal onlyInitializing {
    __ReentrancyGuard_init_unchained();
  }

  function __ReentrancyGuard_init_unchained() internal onlyInitializing {
    ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
    $._status = NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and making it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    _nonReentrantBefore();
    _;
    _nonReentrantAfter();
  }

  function _nonReentrantBefore() private {
    ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
    // On the first call to nonReentrant, _status will be NOT_ENTERED
    if ($._status == ENTERED) {
      revert ReentrancyGuardReentrantCall();
    }

    // Any calls to nonReentrant after this point will fail
    $._status = ENTERED;
  }

  function _nonReentrantAfter() private {
    ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    $._status = NOT_ENTERED;
  }

  /**
   * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
   * `nonReentrant` function in the call stack.
   */
  function _reentrancyGuardEntered() internal view returns (bool) {
    ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
    return $._status == ENTERED;
  }
}

// File contracts/utils/Constants.sol

// Original license: SPDX_License_Identifier: MIT

// Shared constants across the Asset Controller system
library Constants {
  // Role constants
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
  bytes32 public constant CONTROLLER_ROLE = keccak256('CONTROLLER_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');
  bytes32 public constant TRANSFER_ROLE = keccak256('TRANSFER_ROLE');
  bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
  bytes32 public constant CUSTODY_MANAGER_ROLE = keccak256('CUSTODY_MANAGER_ROLE');
  bytes32 public constant CONFIG_MANAGER_ROLE = keccak256('CONFIG_MANAGER_ROLE');
  bytes32 public constant PERMITTED_CONTRACT_ROLE = keccak256('PERMITTED_CONTRACT_ROLE');
  bytes32 public constant FEE_MANAGER_ROLE = keccak256('FEE_MANAGER_ROLE');
  bytes32 public constant LOCK_MANAGER_ROLE = keccak256('LOCK_MANAGER_ROLE');

  // Asset types enum
  enum AssetType {
    REC, // Renewable Energy Certificate
    CarbonCredit // Carbon Credit
  }

  // Currency types enum
  enum CurrencyType {
    USDC, // USD Coin
    USDT // Tether USD
  }
}

// File contracts/interfaces/IConfigs.sol

// Original license: SPDX_License_Identifier: MIT

/// @title IConfigs
interface IConfigs {
  // ============================
  // Events
  // ============================

  event CurrencyWhitelisted(Constants.CurrencyType currency, address indexed currencyAddress);
  event CurrencyRemovedFromWhitelist(Constants.CurrencyType currency);
  event AssetWhitelisted(Constants.AssetType asset, address indexed assetAddress);
  event AssetRemovedFromWhitelist(Constants.AssetType asset);

  event AccessControllerUpdated(address newAccessController);
  event CustodianUpdated(address newCustodian);
  event AssetControllerUpdated(address newAssetController);
  event FeeReceiverContractAddressUpdated(address newFeeReceiver);
  event FeeReceiverUpdated(address oldFeeAddress, address newFeeReceiver);

  // ============================
  // Functions
  // ============================

  /// @dev Returns true if the currency is permitted
  function isPermittedCurrency(Constants.CurrencyType currency) external view returns (bool);
  /// @dev Returns true if the asset is permitted
  function isPermittedAsset(Constants.AssetType asset) external view returns (bool);

  /// @dev Returns the address of the permitted asset for given asset type. Ex RECs, CarbonCredits, etc.
  function assetAddress(Constants.AssetType asset) external view returns (address);
  /// @dev Returns the address of the permitted currency for given currency type. Ex USDC, USDT, etc.
  function currencyAddress(Constants.CurrencyType currency) external view returns (address);

  /// @dev Returns the list of all permitted currency addresses
  function permittedCurrencies() external view returns (address[] memory);
  /// @dev Returns the list of all permitted asset addresses
  function permittedAssets() external view returns (address[] memory);

  /// @dev Returns the fee receiver contract address
  function feeVaultAddress() external view returns (address);
  /// @dev Updates the fee receiver contract address
  function updateFeeVault(address newFeeAddress) external;

  /// @dev Returns the fee receiver address
  function feeReceiverAddress() external view returns (address);
  /// @dev Updates the fee receiver address
  function updateFeeReceiverAddress(address newFeeAddress) external;

  /// @dev Returns the access controller contract address
  function accessControllerAddress() external view returns (address);
  /// @dev Updates the access controller contract address
  function updateAccessController(address newAccessController) external;

  /// @dev Returns the custodian contract address
  function custodianAddress() external view returns (address);
  /// @dev Updates the custodian contract address
  function updateCustodian(address newCustodian) external;

  /// @dev Returns the asset controller contract address
  function assetControllerAddress() external view returns (address);
  /// @dev Updates the asset controller contract address
  function updateAssetController(address newAssetController) external;

  /// @dev adds currency to the permitted currency list and maps it with enum
  function addPermittedCurrencies(Constants.CurrencyType currency, address currencyAddress) external;
  /// @dev removes currency from the permitted currency list
  function removePermittedCurrencies(Constants.CurrencyType currency) external;

  /// @dev add ERC1155 assets to the permitted assets list and maps it with enum
  function addPermittedAssets(Constants.AssetType asset, address assetAddress) external;
  /// @dev removes asset from the permitted assets list
  function removePermittedAssets(Constants.AssetType asset) external;
}

// File contracts/interfaces/IAccessController.sol

// Original license: SPDX_License_Identifier: MIT

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

// File contracts/interfaces/ITokenLockerERC20.sol

// Original license: SPDX_License_Identifier: MIT

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

  /// @dev Emitted when a locker contract is authorized.
  event LockerAuthorized(address indexed locker);

  /// @dev Emitted when a locker contract's authorization is revoked.
  event LockerRevoked(address indexed locker);

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

  // ==================== Locker Management ====================

  /// @notice Authorizes a new locker contract that can lock tokens.
  /// @dev Callable only by the contract owner.
  function authorizeLocker(address locker) external;

  /// @notice Revokes authorization of a locker contract.
  /// @dev Callable only by the contract owner.
  function revokeLocker(address locker) external;
}

// File contracts/utils/Errors.sol

// Original license: SPDX_License_Identifier: MIT

// Shared errors across the Asset Controller system
error NotAuthorized();
error ZeroAddress();
error NotRegistered();
error AlreadyRegistered();
error AmountMismatch();
error InsufficientUnlocked();
error InsufficientBalance();
error AlreadyExists();
error NotExists();
error InvalidContract(address contractAddress);
error TransferFailed(address token, address from, address to, uint256 amount);
error NotPermitted(address caller);
error InsufficientLockedAmount();
error LockerAlreadyAuthorized();
error LockerNotAuthorized();

// File contracts/tokenLocker/TokenLockerUpgradeable.sol

/// @title TokenLockerUpgradeable
/// @notice An upgradeable contract for managing partial locking of ERC-20 token balances.
/// Supports multiple authorized locker contracts and admin override capability.
contract TokenLockerUpgradeable is
  ITokenLockerERC20,
  Initializable,
  AccessControlUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  // ============================
  // State Variables
  // ============================

  IConfigs public configContract;

  // ============================
  // Mappings
  // ============================

  /// @dev Mapping from locker address to user address to locked amount
  mapping(address => mapping(address => uint256)) public lockedAmounts;
  /// @dev Mapping from user address to total locked amount across all lockers
  mapping(address => uint256) public totalLockedAmounts;
  /// @dev Set of authorized locker contracts
  mapping(address => bool) public authorizedLockers;

  // ============================
  // Constructor
  // ============================

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  // ============================
  // Initialization
  // ============================

  /**
   * @dev Initializes the contract with the specified roles and config contract
   * @param _defaultAdmin The address of the default admin
   * @param _configContract The address of the config contract
   */
  function initialize(address _defaultAdmin, address _configContract) public initializer {
    __AccessControl_init();
    __Pausable_init();
    __ReentrancyGuard_init();

    _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);

    if (_configContract == address(0)) revert ZeroAddress();
    configContract = IConfigs(_configContract);
  }

  // ============================
  // Events
  // ============================

  event ConfigContractUpdated(address indexed configContract);

  // ============================
  // Modifiers
  // ============================

  /// @dev Modifier to ensure only authorized locker contracts can call
  modifier onlyAuthorizedLocker() {
    if (!authorizedLockers[_msgSender()]) revert NotPermitted(_msgSender());
    _;
  }

  /// @dev Modifier to ensure only lock managers can call
  modifier onlyLockManager() {
    address accessController = configContract.accessControllerAddress();
    if (accessController == address(0)) revert NotRegistered();

    if (!IAccessController(accessController).hasAdminRole(Constants.LOCK_MANAGER_ROLE, _msgSender())) {
      revert NotPermitted(_msgSender());
    }
    _;
  }

  // ============================
  // Locking Functions
  // ============================

  /**
   * @dev See {ITokenLockerERC20-lock}
   */
  function lock(address user, uint256 amount) external override onlyAuthorizedLocker whenNotPaused {
    if (user == address(0)) revert ZeroAddress();
    if (amount == 0) revert InsufficientBalance();

    // Update locked amounts
    lockedAmounts[_msgSender()][user] += amount;
    totalLockedAmounts[user] += amount;

    emit TokensLocked(_msgSender(), user, amount);
  }

  /**
   * @dev See {ITokenLockerERC20-unlockAll}
   */
  function unlockAll(address user) external override onlyAuthorizedLocker whenNotPaused {
    if (user == address(0)) revert ZeroAddress();

    uint256 amount = lockedAmounts[_msgSender()][user];

    if (amount > 0) {
      // Update locked amounts
      lockedAmounts[_msgSender()][user] = 0;
      totalLockedAmounts[user] -= amount;

      emit TokensUnlocked(_msgSender(), user);
    }
  }

  /**
   * @dev See {ITokenLockerERC20-unlock}
   */
  function unlock(address user, uint256 amount) external override onlyAuthorizedLocker whenNotPaused {
    if (user == address(0)) revert ZeroAddress();
    if (amount == 0) revert InsufficientBalance();
    if (lockedAmounts[_msgSender()][user] < amount) revert InsufficientLockedAmount();

    // Update locked amounts
    lockedAmounts[_msgSender()][user] -= amount;
    totalLockedAmounts[user] -= amount;

    emit TokensUnlocked(_msgSender(), user);
  }

  // ============================
  // Admin Functions
  // ============================

  /**
   * @dev See {ITokenLockerERC20-adminLock}
   */
  function adminLock(address user, uint256 amount) external override onlyLockManager whenNotPaused {
    if (user == address(0)) revert ZeroAddress();
    if (amount == 0) revert InsufficientBalance();

    // Update locked amounts (using admin address as the "locker")
    lockedAmounts[_msgSender()][user] += amount;
    totalLockedAmounts[user] += amount;

    emit TokensAdminLocked(_msgSender(), user, amount);
  }

  /**
   * @dev See {ITokenLockerERC20-adminUnlockAll}
   */
  function adminUnlockAll(address locker, address user) external override onlyLockManager whenNotPaused {
    if (locker == address(0)) revert ZeroAddress();
    if (user == address(0)) revert ZeroAddress();

    uint256 amount = lockedAmounts[locker][user];

    if (amount > 0) {
      // Update locked amounts
      lockedAmounts[locker][user] = 0;
      totalLockedAmounts[user] -= amount;

      emit TokensAdminUnlocked(_msgSender(), user);
    }
  }

  /**
   * @dev See {ITokenLockerERC20-adminUnlock}
   */
  function adminUnlock(address locker, address user, uint256 amount) external override onlyLockManager whenNotPaused {
    if (locker == address(0)) revert ZeroAddress();
    if (user == address(0)) revert ZeroAddress();
    if (amount == 0) revert InsufficientBalance();
    if (lockedAmounts[locker][user] < amount) revert InsufficientLockedAmount();

    // Update locked amounts
    lockedAmounts[locker][user] -= amount;
    totalLockedAmounts[user] -= amount;

    emit TokensAdminUnlocked(_msgSender(), user);
  }

  // ============================
  // View Functions
  // ============================

  /**
   * @dev See {ITokenLockerERC20-getLockedAmountByLocker}
   */
  function getLockedAmountByLocker(address locker, address user) external view override returns (uint256) {
    return lockedAmounts[locker][user];
  }

  /**
   * @dev See {ITokenLockerERC20-getTotalLockedAmount}
   */
  function getTotalLockedAmount(address user) external view override returns (uint256) {
    return totalLockedAmounts[user];
  }

  // ============================
  // Locker Management
  // ============================

  /**
   * @dev See {ITokenLockerERC20-authorizeLocker}
   */
  function authorizeLocker(address locker) external override onlyLockManager {
    if (locker == address(0)) revert ZeroAddress();
    if (authorizedLockers[locker]) revert LockerAlreadyAuthorized();

    authorizedLockers[locker] = true;
    emit LockerAuthorized(locker);
  }

  /**
   * @dev See {ITokenLockerERC20-revokeLocker}
   */
  function revokeLocker(address locker) external override onlyLockManager {
    if (locker == address(0)) revert ZeroAddress();
    if (!authorizedLockers[locker]) revert LockerNotAuthorized();

    authorizedLockers[locker] = false;
    emit LockerRevoked(locker);
  }

  // ============================
  // Additional View Functions
  // ============================

  /**
   * @notice Checks if a locker is authorized
   * @param locker The locker address to check
   * @return True if the locker is authorized
   */
  function isAuthorizedLocker(address locker) external view returns (bool) {
    return authorizedLockers[locker];
  }

  /**
   * @notice Gets the available (unlocked) balance for a user
   * @param user The user address
   * @param totalBalance The user's total token balance
   * @return The available (unlocked) balance
   */
  function getAvailableBalance(address user, uint256 totalBalance) external view returns (uint256) {
    uint256 lockedAmount = totalLockedAmounts[user];
    return totalBalance > lockedAmount ? totalBalance - lockedAmount : 0;
  }

  // ============================
  // Admin Management
  // ============================

  /**
   * @notice Admin override to set the config contract address
   * @dev Only callable by the default admin role
   * @param _configContract The address of the new config contract
   */
  function setConfigContract(address _configContract) external onlyLockManager {
    if (_configContract == address(0)) revert ZeroAddress();
    configContract = IConfigs(_configContract);
    emit ConfigContractUpdated(_configContract);
  }

  /**
   * @dev Pauses the contract
   */
  function pause() external onlyLockManager {
    _pause();
  }

  /**
   * @dev Unpauses the contract
   */
  function unpause() external onlyLockManager {
    _unpause();
  }

  uint256[50] private __gap;
}
