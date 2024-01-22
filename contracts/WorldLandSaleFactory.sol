// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IWorldLandSaleFactory.sol";
import "./interfaces/IWorldLandToken.sol";
import "./external/opensea/IProxyRegistry.sol";
import "./lib/LandAreaManager.sol";

contract WorldLandSaleFactory is IWorldLandSaleFactory, Ownable, LandAreaManager {
    using Strings for string;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    address public immutable proxyRegistryAddress;
    IWorldLandToken public immutable WorldLandToken;

    string public baseTokenURI;

    /*
     * Enforce the existence of only N LandTiles
     */
    uint256 public immutable totalSupply;

    constructor(string memory _baseTokenURI, address _proxyRegistryAddress, IWorldLandToken _WorldLandToken) {
        require(_proxyRegistryAddress != address(0), "invalid ProxyRegistry address");
        require(address(_WorldLandToken) != address(0), "invalid WorldLandToken address");

        proxyRegistryAddress = _proxyRegistryAddress;
        WorldLandToken = _WorldLandToken;
        baseTokenURI = _baseTokenURI;

        totalSupply = (getGridWidth() * 2 + 1) * (getGridHeight() * 2 + 1);
    }

    function name() external pure override returns (string memory) {
        return "world land sale";
    }

    function symbol() external pure override returns (string memory) {
        return "WLD";
    }

    function supportsFactoryInterface() public pure override returns (bool) {
        return true;
    }

    function numOptions() public pure override returns (uint256) {
        return (getGridWidth() * 2 + 1) * (getGridHeight() * 2 + 1);
    }

    function isLandAvailable(uint256 _tokenId) public view returns (bool) {
        return !WorldLandToken.exists(_tokenId);
    }

    function canMint(uint256 _tokenId) public view override returns (bool) {
        return hasEnoughSupply() && isValidTokenId(_tokenId) && isLandAvailable(_tokenId);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    function lazyMint(uint256[] calldata _tokenIds) public override onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // Check if `tokenId` is valid && hasn't been minted yet
            if (WorldLandToken.isValidTokenId(_tokenIds[i]) && !WorldLandToken.exists(_tokenIds[i])) {
                emit Transfer(address(0), owner(), _tokenIds[i]);
            }
        }
    }

    function mint(uint256 _tokenId, address _toAddress) public override {
        // Must be sent from the owner proxy or owner.
        IProxyRegistry proxyRegistry = IProxyRegistry(proxyRegistryAddress);
        assert(address(proxyRegistry.proxies(owner())) == _msgSender() || owner() == _msgSender());
        require(canMint(_tokenId), "Minting is not allowed");
        WorldLandToken.mintTokenId(_toAddress, _tokenId);
    }

    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(address, address _to, uint256 _tokenId) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        IProxyRegistry proxyRegistry = IProxyRegistry(proxyRegistryAddress);
        return address(proxyRegistry.proxies(owner)) == operator;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function ownerOf(uint256) public view returns (address _owner) {
        return owner();
    }

    function hasEnoughSupply() public view returns (bool) {
        uint256 supply = WorldLandToken.totalSupply();
        return supply < totalSupply;
    }
}
