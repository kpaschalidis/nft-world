// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IWorldLandToken.sol";
import "./utils/ContentMixinUpgradeable.sol";
import "./base/BaseERC721Upgradeable.sol";
import "./external/opensea/IProxyRegistry.sol";
import "./lib/LandAreaManager.sol";

contract WorldLandToken is
    IWorldLandToken,
    BaseERC721Upgradeable,
    LandAreaManager,
    AccessControlEnumerableUpgradeable,
    ContextMixinUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string public override baseTokenURI;
    // IPFS content hash of contract-level metadata
    string private _contractURIHash = "";

    struct BoundingBox {
        int256 x;
        int256 y;
    }

    // Mapping token id to bounding box
    mapping(uint256 => BoundingBox) internal boundingBoxes;

    // Proxy Registry
    IProxyRegistry public proxyRegistry;

    function exists(uint256 _tokenId) external view override returns (bool) {
        require(isValidTokenId(_tokenId), "Invalid _tokenId provided");
        return _exists(_tokenId);
    }

    /**
     * @notice Initialize the WorldLandToken and the base contracts, configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(string memory _baseTokenURI, IProxyRegistry _proxyRegistry) external initializer {
        __BaseERC721Upgradeable_init("world land", "WLD");
        __ContextMixinUpgradeable_init();
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());

        baseTokenURI = _baseTokenURI;
        proxyRegistry = _proxyRegistry;

        _pause();
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked("ipfs://", _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _contractURIHash = newContractURIHash;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721Upgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Pause transfers OF World Land token
     */
    function pause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause transfers OF World Land token
     */
    function unpause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    /**
     * @notice Returns the owner of the land with `_tokenId`.
     *
     *  Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOfLand(uint256 _tokenId) public view returns (address) {
        return ownerOf(_tokenId);
    }

    /**
     * @notice Returns the owner of the land with coordinates `_x`, `_y`.
     *
     *  Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOfLand(int256 _x, int256 _y) public view returns (address) {
        uint256 tokenId = getTokenId(_x, _y);
        return ownerOf(tokenId);
    }

    /**
     * @notice Returns the owners of the lands with coordinates `_x`, `_y`
     *
     *  Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOfLandMany(int256[] calldata _x, int256[] calldata _y) public view returns (address[] memory) {
        require(_x.length == _y.length, "length of _x, _y does not match");

        address[] memory owners = new address[](_x.length);
        for (uint256 i = 0; i < _x.length; i++) {
            uint256 tokenId = getTokenId(_x[i], _y[i]);
            owners[i] = ownerOf(tokenId);
        }

        return owners;
    }

    function mintTokenId(address _to, uint256 _tokenId) external override onlyRole(MINTER_ROLE) returns (uint256) {
        require(isValidTokenId(_tokenId), "_tokenId is not valid");

        int256 x = getX(_tokenId);
        int256 y = getY(_tokenId);
        return _mint(_to, _tokenId, x, y);
    }

    function mintTokenIdBatch(
        uint256[] calldata _tokenIds,
        address _toAddress
    ) external override onlyRole(MINTER_ROLE) {
        // Check if all tokenIds are valid. Revert otherwise
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(isValidTokenId(_tokenIds[i]), "_tokenId is not valid");
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            int256 x = getX(_tokenIds[i]);
            int256 y = getY(_tokenIds[i]);
            _mint(_toAddress, _tokenIds[i], x, y);
        }
    }

    function mint(
        address _to,
        int256 _x,
        int256 _y
    ) external override onlyRole(MINTER_ROLE) isInsideBoundaries(_x, _y) returns (uint256) {
        uint256 tokenId = getTokenId(_x, _y);
        return _mint(_to, tokenId, _x, _y);
    }

    function _mint(address _to, uint256 _tokenId, int256 _x, int256 _y) internal returns (uint256) {
        _incrementNextId();
        _safeMint(_to, _tokenId);
        boundingBoxes[_tokenId] = BoundingBox(_x, _y);
        emit WorldLandCreated(_to, _tokenId);
        return _tokenId;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply();
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view override(IERC721Upgradeable, ERC721Upgradeable) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function isValidTokenId(uint256 _tokenId) public pure override(IWorldLandToken, LandAreaManager) returns (bool) {
        return super.isValidTokenId(_tokenId);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixinUpgradeable.msgSender();
    }
}
