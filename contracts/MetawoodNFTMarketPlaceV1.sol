// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IMetawoodNFT.sol";
import "./libraries/TransferHelper.sol";

contract MetawoodNFTMarketPlaceV1 is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _listingCounter;
    IMetawoodNFT public metawoodNFT;

    enum ListingState {
        OPEN,
        CLOSED
    }

    struct Listing {
        uint256 listingId;
        address seller;
        uint256 tokenId;
        uint256 tokenPrice;
        ListingState status;
    }

    mapping(uint256 => Listing) private _listings;
    //1 tokenId should only have 1 listing linked to it always when theere is absolute certainty that 1 tokenId represents 1 token i.e. with supply 1
    mapping(uint256 => uint256) private _tokenIdToListingId;

    event ListingCreated(
        uint256 indexed listingId,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 tokenPrice
    );

    event ListingClosed(uint256 indexed listingId);

    event ListingPriceUpdated(uint256 indexed listingId, uint256 newTokenPrice);

    event NFTPurchased(
        uint256 indexed listingId,
        address buyer,
        address seller,
        uint256 indexed tokenId,
        uint256 tokenPrice
    );

    modifier ensureNonZeroAddress(address addressToCheck) {
        require(addressToCheck != address(0), "MetawoodMarketplaceV1: No zero address");
        _;
    }

    modifier ensureValidListing(uint256 listingId) {
        Listing memory listing = _listings[listingId];
        require(listing.seller != address(0), "MetawoodMarketplaceV1: Invalid Listing");
        require(msg.sender != address(0), "MetawoodMarketplaceV1: Invalid caller address");
        _;
    }

    modifier ensureNFTOwner(uint256 _tokenId) {
        require(metawoodNFT.exists(_tokenId), "MetawoodMarketplaceV1: tokenId is not minted");
        require(
            metawoodNFT.balanceOf(msg.sender, _tokenId) > 0,
            "MetawoodMarketplaceV1: Token Not Owned!"
        );
        _;
    }

    constructor(IMetawoodNFT _metawoodNFT) {
        require(address(_metawoodNFT) != address(0), "Invalid ERC1155 address");
        metawoodNFT = _metawoodNFT;
    }

    function getListingCount() external view returns (uint256) {
        return _listingCounter.current();
    }

    function createListing(uint256 _tokenId, uint256 _tokenPrice)
        external
        nonReentrant
        ensureNFTOwner(_tokenId)
        whenNotPaused
    {
        require(msg.sender != address(0), "MetawoodMarketplaceV1: Invalid caller address");
        require(_tokenPrice > 0, "MetawoodMarketplaceV1: Price must be at least 1 wei");

        Listing memory latestListingForTokenId = _listings[_tokenIdToListingId[_tokenId]];
        if (
            latestListingForTokenId.seller == msg.sender &&
            latestListingForTokenId.status == ListingState.OPEN &&
            latestListingForTokenId.tokenId == _tokenId
        ) {
            revert("MetawoodMarketplaceV1: Listing already exists for this token");
        }

        uint256 listingId = _listingCounter.current();
        _listings[listingId] = Listing(
            listingId,
            msg.sender,
            _tokenId,
            _tokenPrice,
            ListingState.OPEN
        );
        _tokenIdToListingId[_tokenId] = listingId;

        emit ListingCreated(listingId, msg.sender, _tokenId, _tokenPrice);

        _listingCounter.increment();
    }

    function closeListing(uint256 _listingId) external nonReentrant ensureValidListing(_listingId) {
        Listing storage listing = _listings[_listingId];
        require(
            listing.seller == msg.sender,
            "MetawoodMarketplaceV1: Not the seller of the listing!"
        );
        require(
            listing.status == ListingState.OPEN,
            "MetawoodMarketplaceV1: Listing is already closed!!"
        );

        listing.status = ListingState.CLOSED;

        emit ListingClosed(_listingId);
    }

    function changeListingPrice(uint256 _listingId, uint256 _newTokenPrice)
        external
        nonReentrant
        ensureValidListing(_listingId)
        whenNotPaused
    {
        Listing storage listing = _listings[_listingId];
        require(
            listing.seller == msg.sender,
            "MetawoodMarketplaceV1: Not the seller of the listing!"
        );
        require(
            listing.status == ListingState.OPEN,
            "MetawoodMarketplaceV1: Listing is already closed!!"
        );
        require(
            metawoodNFT.balanceOf(msg.sender, listing.tokenId) > 0,
            "MetawoodMarketplaceV1: Token Not Owned!"
        );
        require(_newTokenPrice > 0, "MetawoodMarketplaceV1: New Price must be at least 1 wei");

        listing.tokenPrice = _newTokenPrice;

        emit ListingPriceUpdated(_listingId, _newTokenPrice);
    }

    //one listing one tokenId one seller

    function purchaseNFT(uint256 _listingId)
        external
        payable
        nonReentrant
        ensureValidListing(_listingId)
        whenNotPaused
    {
        Listing storage listing = _listings[_listingId];

        require(msg.sender != address(0), "MetawoodMarketplaceV1: Invalid caller address");
        require(
            listing.status == ListingState.OPEN,
            "MetawoodMarketplaceV1: The item is not for sale!!"
        );
        require(listing.seller != msg.sender, "MetawoodMarketplaceV1: Cannot Buy Owned Item!");
        //update error message here in new deployment
        require(msg.value == listing.tokenPrice, "MetawoodMarketplaceV1: Not enough funds sent");
        require(
            metawoodNFT.isApprovedForAll(listing.seller, address(this)),
            "MetawoodMarketplaceV1: Not Approved for moving the listing token!"
        );
        require(
            metawoodNFT.balanceOf(listing.seller, listing.tokenId) > 0,
            "MetawoodMarketplaceV1: Invalid Listing. Token Not Owned by seller!"
        );

        TransferHelper.safeTransferETH(listing.seller, listing.tokenPrice);
        metawoodNFT.safeTransferFrom(listing.seller, msg.sender, listing.tokenId, 1, "0x00");
        listing.status = ListingState.CLOSED;

        require(
            metawoodNFT.balanceOf(msg.sender, listing.tokenId) > 0,
            "MetawoodMarketplaceV1: Token Not Sold!"
        );

        emit NFTPurchased(
            _listingId,
            msg.sender,
            listing.seller,
            listing.tokenId,
            listing.tokenPrice
        );
        emit ListingClosed(_listingId);
    }

    receive() external payable {}

    function withdrawERC20(IERC20 _token) external onlyOwner nonReentrant {
        TransferHelper.safeTransfer(address(_token), msg.sender, _token.balanceOf(address(this)));
    }

    function withdrawReceivedEther() external onlyOwner nonReentrant {
        TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //Getter Functions

    function getListing(uint256 _listingId) external view returns (Listing memory listing) {
        listing = _listings[_listingId];
    }

    function getLatestListingForToken(uint256 _tokenId)
        external
        view
        returns (Listing memory listing)
    {
        require(metawoodNFT.exists(_tokenId), "MetawoodMarketplaceV1: tokenId is not minted");
        listing = _listings[_tokenIdToListingId[_tokenId]];
    }

    function getLatestListings(uint256 threshold) external view returns (Listing[] memory) {
        Listing[] memory listings = new Listing[](threshold);
        uint256 count = _listingCounter.current();
        uint256 found = 0;
        for (; found < threshold && count > 0; count--) {
            if (_listings[count - 1].status == ListingState.OPEN) {
                listings[found] = _listings[count - 1];
                found++;
            }
        }
        return listings;
    }

    function getOpenListings(address _user) external view returns (Listing[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < _listingCounter.current(); i++) {
            if (_listings[i].status == ListingState.OPEN && _listings[i].seller == _user) {
                count++;
            }
        }
        Listing[] memory listings = new Listing[](count);
        for (uint256 i = 0; i < _listingCounter.current(); i++) {
            if (_listings[i].status == ListingState.OPEN && _listings[i].seller == _user) {
                listings[count - 1] = _listings[i];
                count--;
            }
        }
        return listings;
    }

    function getAllOpenListings() external view returns (Listing[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < _listingCounter.current(); i++) {
            if (_listings[i].status == ListingState.OPEN) {
                count++;
            }
        }
        Listing[] memory listings = new Listing[](count);
        for (uint256 i = 0; i < _listingCounter.current(); i++) {
            if (_listings[i].status == ListingState.OPEN) {
                listings[count - 1] = _listings[i];
                count--;
            }
        }
        return listings;
    }

    function getOwnedTokens(address _user) external view returns (uint256[] memory) {
        uint256 count = 0;
        uint256 tokenCount = metawoodNFT.getTokenCount();
        for (uint256 i = 0; i < tokenCount; i++) {
            if (metawoodNFT.balanceOf(_user, i) > 0) {
                count++;
            }
        }
        uint256[] memory tokenIds = new uint256[](count);
        uint256 counter = 0;
        for (uint256 i = 0; i < tokenCount; i++) {
            if (metawoodNFT.balanceOf(_user, i) > 0) {
                tokenIds[counter] = i;
                counter++;
            }
        }
        return tokenIds;
    }
}
