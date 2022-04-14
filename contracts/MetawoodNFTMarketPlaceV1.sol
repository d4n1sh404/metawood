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
        address seller;
        uint256 tokenId;
        uint256 tokenPrice;
        ListingState status;
    }

    mapping(uint256 => Listing) private _listings;

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
        uint256 listingId = _listingCounter.current();
        _listings[listingId] = Listing(msg.sender, _tokenId, _tokenPrice, ListingState.OPEN);
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

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //Getter Functions

    function getListing(uint256 _listingId) external view returns (Listing memory listing) {
        listing = _listings[_listingId];
    }
}
