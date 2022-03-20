// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./MetawoodNft.sol";

contract MetawoodMarketPlace is Ownable {
    MetawoodNft metawoodNft;

    constructor(address metawoodNftAddress) {
        metawoodNft = MetawoodNft(metawoodNftAddress);
    }

    using Counters for Counters.Counter;

    enum ListingState {
        OPEN,
        CLOSED
    }

    Counters.Counter private _listingCount;

    struct Listing {
        uint256 id;
        address creator;
        uint256 tokenId;
        uint256 price;
        ListingState status;
    }

    struct User {
        address userId;
        string data;
    }

    mapping(uint256 => Listing) private _listings;
    mapping(string => IERC20) private _supportedTokens;
    mapping(address => User) users;

    function addSupportedToken(string memory tokenName, address tokenContract)
        public
    {
        _supportedTokens[tokenName] = IERC20(tokenContract);
    }

    function createListing(uint256 tokenId, uint256 tokenPrice) public {
        require(
            metawoodNft.balanceOf(msg.sender, tokenId) > 0,
            "Token Not Owned!"
        );

        _listingCount.increment();
        uint256 id = _listingCount.current();

        _listings[id] = Listing(
            id,
            msg.sender,
            tokenId,
            tokenPrice,
            ListingState.OPEN
        );

        //get approval for transfer from msg.sender
        // metawoodNft.setApprovalForAll(address(this), true);

        // TODO emit event
    }

    function getListing(uint256 listingId)
        public
        view
        returns (Listing memory listing)
    {
        return _listings[listingId];
    }

    function getLatestListings(uint256 threshold)
        public
        view
        returns (Listing[] memory)
    {
        Listing[] memory listings = new Listing[](threshold);
        uint256 count = _listingCount.current();
        uint256 found = 0;
        for (; found < threshold && count > 0; count--) {
            if (_listings[count].status == ListingState.OPEN) {
                listings[found] = _listings[count];
                found++;
            }
        }

        return listings;
    }

    function getOwnedTokens() public view returns (uint256[] memory) {
        uint256 count = 0;
        uint256 tokenCount = metawoodNft.getTokenCount();
        for (uint256 i = 1; i <= tokenCount; i++) {
            if (metawoodNft.balanceOf(msg.sender, i) > 0) {
                count++;
            }
        }
        uint256[] memory tokenIds = new uint256[](count);
        uint256 counter = 0;
        for (uint256 i = 1; i <= tokenCount; i++) {
            if (metawoodNft.balanceOf(msg.sender, i) > 0) {
                tokenIds[counter] = i;
                counter++;
            }
        }
        return tokenIds;
    }

    function getOpenListings() public view returns (Listing[] memory) {
        uint256 count = 0;

        for (uint256 i = 1; i <= _listingCount.current(); i++) {
            if (
                _listings[i].status == ListingState.OPEN &&
                _listings[i].creator == msg.sender
            ) {
                count++;
            }
        }

        Listing[] memory listings = new Listing[](count);
        for (uint256 i = 1; i <= _listingCount.current(); i++) {
            if (
                _listings[i].status == ListingState.OPEN &&
                _listings[i].creator == msg.sender
            ) {
                listings[count-1] = _listings[i];
                count--;
            }
        }
        return listings;
    }

    function buyNft(uint256 listingId) public {
        require(
            _listings[listingId].status == ListingState.OPEN,
            "The item is not for sale!!"
        );
        require(
            _supportedTokens["native"].balanceOf(msg.sender) >=
                _listings[listingId].price,
            "Insufficient funds for purchase!!"
        );

        

        metawoodNft.safeTransferFrom(
            _listings[listingId].creator,
            msg.sender,
            _listings[listingId].tokenId,
            1,
            "0x00"
        );

        _supportedTokens["native"].transferFrom(
            msg.sender,
            _listings[listingId].creator,
            _listings[listingId].price
        );

        _listings[listingId].status = ListingState.CLOSED;
        // TODO emit event
    }

    function addUser(address userAddress, string memory data) public {
        users[userAddress] = User(userAddress, data);
    }
}
