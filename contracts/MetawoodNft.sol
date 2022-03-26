// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./MetawoodMarketPlace.sol";

contract MetawoodNft is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    using Counters for Counters.Counter;
    MetawoodMarketPlace private _marketPlace;
    Counters.Counter private _tokenCount;

    constructor() ERC1155("") {}

    event SetTokenURI(uint256 _id, string _uri);
    mapping(uint256 => string) private _uris;

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _uris[tokenId];
    }

    //function for uri override for specific use cases;
    function setTokenURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        _uris[tokenId] = tokenURI;
        emit SetTokenURI(tokenId, tokenURI);
    }

    //default uri set funciton/ can remove
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        uint256 amount,
        string memory tokenUrl,
        bytes memory data
    ) public {
        _tokenCount.increment();
        _mint(msg.sender, _tokenCount.current(), amount, data);
        //Fix for set uri should be done by the minter without modifiers
        _uris[_tokenCount.current()] = tokenUrl;
        setApprovalForAll(address(_marketPlace), true);

        emit SetTokenURI(_tokenCount.current(), tokenUrl);
    }

    function getTokenCount() public view returns (uint256) {
        return _tokenCount.current();
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        _mintBatch(to, ids, amounts, data);
    }

    function setMarketPlace(address marketPlaceAddress) public onlyOwner {
        _marketPlace = MetawoodMarketPlace(marketPlaceAddress);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
