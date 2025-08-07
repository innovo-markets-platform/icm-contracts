// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./IERC2771Recipient.sol";

/**
 * @title ERC2771Recipient
 * @notice Implementation of ERC2771Recipient pattern for gasless transactions
 */
abstract contract ERC2771Recipient is IERC2771Recipient {
    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address) {
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * @dev Return the sender of this call.
     * If the call came through our trusted forwarder, return the original sender.
     * Otherwise, return `msg.sender`.
     * Should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * @dev Return the msg.data of this call.
     * If the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * Should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}
