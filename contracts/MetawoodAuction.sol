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
    uint256 public bidIncreaseThreshold = 10**15;

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
        address payable creator; // Creator of the Auction
        uint256 bidIncreaseThreshold;
        uint256 auctionEnd;
        uint256 minimumBid;
        uint256 highestBid;
        address payable highestBidder;
        uint256[] bids;
        address[] bidders;
        // address payable[] bidders;
        AuctionState status;
    }

    mapping(uint256 => Auction) private _auctions;

    modifier ensureNFTOwner(uint256 _tokenId) {
        require(metawoodNFT.exists(_tokenId), "Non existing token");
        require(metawoodNFT.balanceOf(msg.sender, _tokenId) > 0, "Token Not Owned!");
        _;
    }

    modifier ensureValidAuction(uint256 _auctionId) {
        Auction memory auction = _auctions[_auctionId];
        require(auction.creator != address(0), "Invalid Auction");
        require(msg.sender != address(0), "Invalid caller address");
        _;
    }

    modifier ensureActiveAuction(uint256 _auctionId) {
        Auction memory auction = _auctions[_auctionId];
        require(auction.status == AuctionState.ACTIVE, "Auction not active");

        _;
    }

    modifier ensureAuctionCreator(uint256 _auctionId) {
        Auction memory auction = _auctions[_auctionId];
        require(auction.creator == msg.sender, "Not the auction creator");
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
            creator: payable(msg.sender),
            bidIncreaseThreshold: bidIncreaseThreshold,
            auctionEnd: _auctionEnd,
            minimumBid: _minimumBid,
            highestBid: 0,
            highestBidder: payable(address(0)),
            bids: new uint256[](0),
            bidders: new address[](0),
            status: AuctionState.ACTIVE
        });

        metawoodNFT.safeTransferFrom(msg.sender, address(this), _nftId, 1, "0x00");
        _auctions[auctionId] = _auction;
        _auctionCounter.increment();
    }

    function makeBid(uint256 _auctionId)
        external
        payable
        ensureValidAuction(_auctionId)
        ensureActiveAuction(_auctionId)
    {
        Auction storage _auction = _auctions[_auctionId];

        require(
            msg.value >= _auction.highestBid + bidIncreaseThreshold,
            "Bid amount less than max bid"
        );

        //return amount to old bidder
        bool success = _auction.highestBidder.send(_auction.highestBid);
        require(success, "Old highest bid payback failed");
        //update max bidder
        _auction.highestBid = msg.value;
        _auction.highestBidder = payable(msg.sender);
        _auction.bids.push(msg.value);
        _auction.bidders.push(msg.sender);
    }

    function settleAuction(uint256 _auctionId)
        external
        ensureValidAuction(_auctionId)
        ensureAuctionCreator(_auctionId)
        ensureActiveAuction(_auctionId)
    {
        Auction storage _auction = _auctions[_auctionId];
        // require(_auction.auctionEnd <= block.timestamp, "Deadline did not pass yet");

        if (_auction.bids.length == 0) {
            // There are no bids, return the nft to creator
            _auction.nftContract.safeTransferFrom(
                address(this),
                _auction.creator,
                _auction.nftId,
                1,
                "0x00"
            );
        } else {
            // send
            bool success = _auction.creator.send(_auction.highestBid);

            require(success, "Paying highest bidder failed");

            // for (uint256 i = 0; i < _auction.bids.length; i++) {
            //     if (_auction.bidders[i] != _auction.highestBidder) {
            //         (success) = _auction.bidders[i].send(_auction.bids[i]);
            //         require(success);
            //     }
            // }

            //Send the nft to highest bidder
            _auction.nftContract.safeTransferFrom(
                address(this),
                _auction.highestBidder,
                _auction.nftId,
                1,
                "0x00"
            );
        }

        _auction.status = AuctionState.INACTIVE;
    }
}
