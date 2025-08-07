// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * @title IERC2771Recipient
 * @notice Interface for ERC2771Recipient pattern implementation
 */
interface IERC2771Recipient {
    /**
     * @dev Returns the address of the trusted forwarder
     */
    function trustedForwarder() external view returns (address);

    /**
     * @dev Returns true if the forwarder is trusted
     */
    function isTrustedForwarder(address forwarder) external view returns (bool);
}
