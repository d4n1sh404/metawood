// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./libraries/ContextMixin.sol";

contract MetawoodNFT is
    ERC1155,
    ContextMixin,
    Ownable,
    AccessControl,
    Pausable,
    ERC1155Burnable,
    ERC1155Supply
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint256 => string) private _uris;

    address public metawoodMarketPlace;

    event SetTokenURI(uint256 tokenId, string tokenURI);
    event SetBaseURI(string metadataBaseURI);
    event MetawoodNFTMinted(uint256 tokenId, address creator);

    modifier ensureNonZeroAddress(address addressToCheck) {
        require(addressToCheck != address(0), "Metawood NFT: No zero address");
        _;
    }

    constructor(string memory _metadataBaseURI) ERC1155(_metadataBaseURI) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMetawoodMarketPlace(address _newMetawoodMarketPlace)
        external
        onlyOwner
        ensureNonZeroAddress(_newMetawoodMarketPlace)
    {
        metawoodMarketPlace = _newMetawoodMarketPlace;
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        return _uris[_tokenId];
    }

    //use properly since there are no requires here
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external onlyOwner {
        _uris[_tokenId] = _tokenURI;
        emit SetTokenURI(_tokenId, _tokenURI);
    }

    function setMetadataBaseURI(string memory _newMetadataBaseURI) external onlyOwner {
        _setURI(_newMetadataBaseURI);
        emit SetBaseURI(_newMetadataBaseURI);
    }

    function getTokenCount() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function mint(
        address _account,
        uint256 _amount,
        string memory _tokenUrl,
        bytes memory _data
    ) external onlyRole(MINTER_ROLE) ensureNonZeroAddress(_account) {
        require(_amount >= 1, "MetawoodNFT: invalid amount parameter");
        _mint(_account, _tokenIdCounter.current(), _amount, _data);
        _uris[_tokenIdCounter.current()] = _tokenUrl;
        emit MetawoodNFTMinted(_tokenIdCounter.current(), _account);
        _tokenIdCounter.increment();
    }

    //Implementation similar to mint (not for creating supply of single tokenID but batch minting NFTs with any supply)
    //Be careful during minting and batch minting. Test thoroughly
    function mintBatch(
        address _account,
        uint256[] memory _amounts,
        string[] memory _tokenUrls,
        bytes memory _data
    ) external onlyRole(MINTER_ROLE) ensureNonZeroAddress(_account) {
        require(
            _tokenUrls.length == _amounts.length,
            "MetawoodNFT: tokenUrls and amounts length mismatch"
        );
        uint256[] memory _ids = new uint256[](_amounts.length);
        for (uint256 i = 0; i < _amounts.length; i++) {
            require(_amounts[i] >= 1, "MetawoodNFT: invalid amount parameter");
            _ids[i] = _tokenIdCounter.current();
            _uris[_tokenIdCounter.current()] = _tokenUrls[i];
            emit MetawoodNFTMinted(_tokenIdCounter.current(), _account);
            _tokenIdCounter.increment();
        }
        _mintBatch(_account, _ids, _amounts, _data);
    }

    //opensea suported methods

    /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
        if (
            _operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101) ||
            _operator == address(metawoodMarketPlace)
        ) {
            return true;
        }
        // otherwise, use the default ERC1155.isApprovedForAll()
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
