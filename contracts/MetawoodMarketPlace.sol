// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IMetawoodNFT.sol";

contract MetawoodMarketPlace is Ownable, ReentrancyGuard {
    // using SafeMath for uint256;
    // using SafeERC20 for IERC20;
    // using Counters for Counters.Counter;
    // Counters.Counter private _listingCounter;
    // IMetawoodNFT public metawoodNFT;
    // enum ListingState {
    //     OPEN,
    //     CLOSED
    // }
    // struct Listing {
    //     address creator;
    //     uint256 tokenId;
    //     uint256 price;
    //     ListingState status;
    // }
    // mapping(uint256 => Listing) private _listings;
    // event ListingCreated(
    //     uint256 indexed listingId,
    //     address indexed creator,
    //     uint256 indexed tokenId,
    //     uint256 tokenPrice
    // );
    // event ListingClosed(uint256 listingId);
    // event NFTBuy(uint256 tokenId, uint256 tokenPrice, uint256 listingId, address indexed buyer);
    // modifier ensureNonZeroAddress(address addressToCheck) {
    //     require(addressToCheck != address(0), "No zero address");
    //     _;
    // }
    // constructor(IMetawoodNFT _metawoodNFT) {
    //     require(address(_metawoodNFT) != address(0), "Invalid ERC1155 address");
    //     metawoodNFT = _metawoodNFT;
    // }
    // function createListing(uint256 _tokenId, uint256 _tokenPrice) external nonReentrant {
    //     require(metawoodNFT.balanceOf(msg.sender, _tokenId) > 0, "Token Not Owned!");
    //     uint256 id = _listingCounter.current();
    //     _listings[id] = Listing(msg.sender, _tokenId, _tokenPrice, ListingState.OPEN);
    //     _listingCounter.increment();
    //     emit ListingCreated(id, msg.sender, _tokenId, _tokenPrice);
    // }
    // function closeListing(uint256 listingId) external nonReentrant {
    //     require(_listings[listingId].creator == msg.sender, "Not the creator of the listing!");
    //     require(_listings[listingId].status == ListingState.OPEN, "Listing is already closed!!");
    //     _listings[listingId].status = ListingState.CLOSED;
    //     emit ListingClosed(listingId);
    // }
    // function getListing(uint256 listingId) external view returns (Listing memory listing) {
    //     return _listings[listingId];
    // }
    // function getLatestListings(uint256 threshold) external view returns (Listing[] memory) {
    //     Listing[] memory listings = new Listing[](threshold);
    //     uint256 count = _listingCounter.current();
    //     uint256 found = 0;
    //     for (; found < threshold && count > 0; count--) {
    //         if (_listings[count].status == ListingState.OPEN) {
    //             listings[found] = _listings[count];
    //             found++;
    //         }
    //     }
    //     return listings;
    // }
    // function getOwnedTokens(address _user) external view returns (uint256[] memory) {
    //     uint256 count = 0;
    //     uint256 tokenCount = metawoodNFT.getTokenCount();
    //     for (uint256 i = 1; i <= tokenCount; i++) {
    //         if (metawoodNFT.balanceOf(_user, i) > 0) {
    //             count++;
    //         }
    //     }
    //     uint256[] memory tokenIds = new uint256[](count);
    //     uint256 counter = 0;
    //     for (uint256 i = 1; i <= tokenCount; i++) {
    //         if (metawoodNFT.balanceOf(_user, i) > 0) {
    //             tokenIds[counter] = i;
    //             counter++;
    //         }
    //     }
    //     return tokenIds;
    // }
    // //users only listings
    // function getOpenListings(address _user) external view returns (Listing[] memory) {
    //     uint256 count = 0;
    //     for (uint256 i = 1; i <= _listingCounter.current(); i++) {
    //         if (_listings[i].status == ListingState.OPEN && _listings[i].creator == _user) {
    //             count++;
    //         }
    //     }
    //     Listing[] memory listings = new Listing[](count);
    //     for (uint256 i = 1; i <= _listingCounter.current(); i++) {
    //         if (_listings[i].status == ListingState.OPEN && _listings[i].creator == _user) {
    //             listings[count - 1] = _listings[i];
    //             count--;
    //         }
    //     }
    //     return listings;
    // }
    // //all open listings
    // function getAllOpenListings() external view returns (Listing[] memory) {
    //     uint256 count = 0;
    //     for (uint256 i = 1; i <= _listingCounter.current(); i++) {
    //         if (_listings[i].status == ListingState.OPEN) {
    //             count++;
    //         }
    //     }
    //     Listing[] memory listings = new Listing[](count);
    //     for (uint256 i = 1; i <= _listingCounter.current(); i++) {
    //         if (_listings[i].status == ListingState.OPEN) {
    //             listings[count - 1] = _listings[i];
    //             count--;
    //         }
    //     }
    //     return listings;
    // }
    // function buyNft(uint256 listingId) external nonReentrant {
    //     require(_listings[listingId].status == ListingState.OPEN, "The item is not for sale!!");
    //     require(
    //         _supportedTokens["native"].balanceOf(msg.sender) >= _listings[listingId].price,
    //         "Insufficient funds!!"
    //     );
    //     require(_listings[listingId].creator != msg.sender, "Cannot Buy Owned Item!");
    //     metawoodNFT.safeTransferFrom(
    //         _listings[listingId].creator,
    //         msg.sender,
    //         _listings[listingId].tokenId,
    //         1,
    //         "0x00"
    //     );
    //     _supportedTokens["native"].transferFrom(
    //         msg.sender,
    //         _listings[listingId].creator,
    //         _listings[listingId].price
    //     );
    //     _listings[listingId].status = ListingState.CLOSED;
    //     emit NFTBuy(
    //         _listings[listingId].tokenId,
    //         _listings[listingId].price,
    //         listingId,
    //         msg.sender
    //     );
    //     emit ListingClosed(listingId);
    // }
}
