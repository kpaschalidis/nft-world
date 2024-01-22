// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract BaseERC721Upgradeable is
    Initializable,
    ERC721Upgradeable,
    ERC721PausableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /*
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs.
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */
    CountersUpgradeable.Counter private _id;

    function __BaseERC721Upgradeable_init(
        string memory name,
        string memory symbol
    ) internal onlyInitializing {
        __ERC721_init(name, symbol);
        __ERC721Pausable_init();
    }

    function _getNextTokenId() internal view returns (uint256) {
        return _id.current();
    }

    function _incrementNextId() internal {
        _id.increment();
    }

    /**
     * @dev Returns the total tokens minted so far. 1 is always subtracted from the Counter since it tracks
     * the next available tokenId.
     */
    function _totalSupply() internal view returns (uint256) {
        return _id.current();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Upgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}
