// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC1155NFT.sol";

contract MetawoodMarketPlace is Ownable, ERC1155NFT {
    constructor() ERC1155NFT() {}

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
        require(balanceOf(msg.sender, tokenId) > 0, "Token Not Owned!");

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
        setApprovalForAll(address(this), true);

        // TODO emit event
    }

    function buyNFT(uint256 listingId) public {
        require(
            _listings[listingId].status == ListingState.OPEN,
            "The item is not for sale!!"
        );
        require(
            _supportedTokens["native"].balanceOf(msg.sender) >=
                _listings[listingId].price,
            "Insufficient funds for purchase!!"
        );

        safeTransferFrom(
            _listings[listingId].creator,
            msg.sender,
            _listings[listingId].tokenId,
            1,
            "0x00"
        );

        _listings[listingId].status = ListingState.CLOSED;
        // TODO emit event
    }

    function addUser(address userAddress, string memory data) public {
        users[userAddress] = User(userAddress, data);
    }
}
