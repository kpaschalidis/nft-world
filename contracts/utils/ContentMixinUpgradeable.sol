// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract ContextMixinUpgradeable is ContextUpgradeable {
    function __ContextMixinUpgradeable_init() internal onlyInitializing {
        __Context_init();
    }

    function __ContextMixinUpgradeable_init_unchained() internal onlyInitializing {
        __Context_init_unchained();
    }

    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}
