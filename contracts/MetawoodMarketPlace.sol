// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC1155NFT.sol";

contract MetawoodMarketPlace is Ownable {
    constructor() {}

    enum ListingState {
        OPEN,
        CLOSED
    }
    //use zeppeplien counter later
    uint256 listingCount = 0;

    struct Listing {
        uint256 id;
        address creator;
        uint256 tokenId;
        uint256 tokenType;
        uint256 price;
        ListingState status;
    }

    struct User {
        address userId;
        string data;
    }

    mapping(uint256 => Listing) listings;
    mapping(address => User) users;

    function putForSale(
        uint256 tokenId,
        uint256 tokenType,
        uint256 tokenPrice
    ) public {
        listingCount++;
        listings[listingCount] = Listing(
            listingCount,
            msg.sender,
            tokenId,
            tokenType,
            tokenPrice,
            ListingState.OPEN
        );
    }

    function addUser(address userAddress, string memory data) public {
        users[userAddress] = User(userAddress, data);
    }
}
