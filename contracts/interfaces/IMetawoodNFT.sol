//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IMetawoodNFT is IERC1155 {
    function setMetawoodMarketPlace(address _newMetawoodMarketPlace) external;

    function uri(uint256 _tokenId) external view returns (string memory);

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external;

    function setMetadataBaseURI(string memory _newMetadataBaseURI) external;

    function getTokenCount() external view returns (uint256);

    function mint(
        address _account,
        uint256 _amount,
        string memory _tokenUrl,
        bytes memory _data
    ) external;

    function mintBatch(
        address _account,
        uint256[] memory _amounts,
        string[] memory _tokenUrls,
        bytes memory _data
    ) external;

    function totalSupply(uint256 id) external view returns (uint256);

    function exists(uint256 id) external view returns (bool);
}
