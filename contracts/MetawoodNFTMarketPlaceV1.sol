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
        require(addressToCheck != address(0), "Metawood Marketplace: No zero address");
        _;
    }

    modifier ensureValidListing(uint256 listingId) {
        Listing memory listing = _listings[listingId];
        require(listing.seller != address(0), "Metawood Marketplace: Invalid Listing");
        require(msg.sender != address(0));
        _;
    }

    modifier ensureNFTOwner(uint256 _tokenId) {
        require(metawoodNFT.exists(_tokenId), "Metawood Marketplace: tokenId is not minted");
        require(
            metawoodNFT.balanceOf(msg.sender, _tokenId) > 0,
            "Metawood Marketplace: Token Not Owned!"
        );
        _;
    }

    constructor(IMetawoodNFT _metawoodNFT) {
        require(address(_metawoodNFT) != address(0), "Invalid ERC1155 address");
        metawoodNFT = _metawoodNFT;
    }

    function createListing(uint256 _tokenId, uint256 _tokenPrice)
        external
        nonReentrant
        ensureNFTOwner(_tokenId)
        whenNotPaused
    {
        require(msg.sender != address(0));
        require(_tokenPrice > 0, "Metawood Marketplace: Price must be at least 1 wei");
        Listing memory latestListing = _listings[_tokenIdToListingId[_tokenId]];
        if (latestListing.seller == msg.sender && latestListing.status == ListingState.OPEN)
            revert("Token Owner has already created listing for this tokenId");
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
            "Metawood Marketplace: Not the seller of the listing!"
        );
        require(
            listing.status == ListingState.OPEN,
            "Metawood Marketplace: Listing is already closed!!"
        );
        require(
            metawoodNFT.balanceOf(msg.sender, listing.tokenId) > 0,
            "Metawood Marketplace: Token Not Owned!"
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
            "Metawood Marketplace: Not the seller of the listing!"
        );
        require(
            listing.status == ListingState.OPEN,
            "Metawood Marketplace: Listing is already closed!!"
        );
        require(
            metawoodNFT.balanceOf(msg.sender, listing.tokenId) > 0,
            "Metawood Marketplace: Token Not Owned!"
        );
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

        require(
            listing.status == ListingState.OPEN,
            "Metawood Marketplace: The item is not for sale!!"
        );
        require(listing.seller != msg.sender, "Metawood Marketplace: Cannot Buy Owned Item!");
        require(msg.value == listing.tokenPrice, "Metawood Marketplace: Not enough funds sent");
        require(
            metawoodNFT.isApprovedForAll(listing.seller, address(this)),
            "Metawood Marketplace: Not Approved for moving the listing token!"
        );

        TransferHelper.safeTransferETH(listing.seller, listing.tokenPrice);
        metawoodNFT.safeTransferFrom(listing.seller, msg.sender, listing.tokenId, 1, "0x00");
        listing.status = ListingState.CLOSED;

        require(
            metawoodNFT.balanceOf(msg.sender, listing.tokenId) > 0,
            "Metawood Marketplace: Token Not Sold!"
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

    function getLatestListings(uint256 threshold) external view returns (Listing[] memory) {
        Listing[] memory listings = new Listing[](threshold);
        uint256 count = _listingCounter.current();
        uint256 found = 0;
        for (; found < threshold && count > 0; count--) {
            if (_listings[count].status == ListingState.OPEN) {
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
