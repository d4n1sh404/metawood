// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IMetawoodNFT.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MetawoodAuction {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _auctionCounter;
    IMetawoodNFT public metawoodNFT;

    constructor(address _nftContract) {
        metawoodNFT = IMetawoodNFT(_nftContract);
    }

    enum AuctionState {
        INACTIVE,
        ACTIVE
    }

    struct Auction {
        uint256 id;
        IMetawoodNFT nftContract;
        uint256 nftId; // NFT Id
        address creator; // Creator of the Auction
        uint256 auctionEnd;
        uint256 minimumBid;
        uint256 highestBid;
        address highestBidder;
        uint256[] bids;
        address[] bidders;
        AuctionState status;
    }

    mapping(uint256 => Auction) private _auctions;

    modifier ensureNFTOwner(uint256 _tokenId) {
        require(metawoodNFT.exists(_tokenId), "Non existing token");
        require(metawoodNFT.balanceOf(msg.sender, _tokenId) > 0, "Token Not Owned!");
        _;
    }

    function createAuction(
        uint256 _nftId,
        uint256 _minimumBid,
        uint256 _auctionEnd
    ) external ensureNFTOwner(_nftId) {
        require(msg.sender != address(0), "Invalid caller address");
        require(_auctionEnd > 0, "Invalid auctionEnd value");

        uint256 auctionId = _auctionCounter.current();

        Auction memory _auction = Auction({
            id: auctionId,
            nftContract: metawoodNFT,
            nftId: _nftId,
            creator: msg.sender,
            auctionEnd: _auctionEnd,
            minimumBid: _minimumBid,
            highestBid: 0,
            highestBidder: address(0),
            //bid and bidders to single struct!
            bids: new uint256[](0),
            bidders: new address[](0),
            status: AuctionState.ACTIVE
        });

        metawoodNFT.safeTransferFrom(msg.sender, address(this), _nftId, 1, "0x00");
        _auctions[auctionId] = _auction;
        _auctionCounter.increment();

    }

    function settleAuction() external {}
}
