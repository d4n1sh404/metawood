// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IMetawoodNFT.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MetawoodAuction is ERC1155Holder, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _auctionCounter;
    IMetawoodNFT public metawoodNFT;

    uint256 public bidIncreaseThreshold = 10**15;

    constructor(address _nftContract) {
        metawoodNFT = IMetawoodNFT(_nftContract);
    }

    enum AuctionState {
        CLOSED,
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

    modifier ensureNonZeroAddress(address addressToCheck) {
        require(addressToCheck != address(0), "Zero address!");
        _;
    }

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

    // Transactions

    function createAuction(
        uint256 _nftId,
        uint256 _minimumBid,
        uint256 _auctionEnd
    ) external nonReentrant ensureNFTOwner(_nftId) {
        require(msg.sender != address(0), "Invalid caller address");
        require(_auctionEnd > 0 && _auctionEnd > block.timestamp, "Invalid auctionEnd time");

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
        nonReentrant
        ensureValidAuction(_auctionId)
        ensureActiveAuction(_auctionId)
    {
        Auction storage _auction = _auctions[_auctionId];
        require(msg.sender != _auction.creator, "Cannont bid on own auction!");
        require(block.timestamp <= _auction.auctionEnd, "Auction Deadline passed!");
        require(
            msg.value >= _auction.minimumBid &&
                msg.value >= _auction.highestBid + bidIncreaseThreshold,
            "Bid amount less than max bid threshold"
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
        nonReentrant
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

        _auction.status = AuctionState.CLOSED;
    }

    function closeAuction(uint256 _auctionId)
        external
        nonReentrant
        ensureValidAuction(_auctionId)
        ensureAuctionCreator(_auctionId)
        ensureActiveAuction(_auctionId)
    {
        Auction storage _auction = _auctions[_auctionId];

        //return the highest bid
        if (_auction.bids.length > 0) {
            bool success = _auction.highestBidder.send(_auction.highestBid);
            require(success, "Highest bid payback failed");
        }
        //return the nft
        _auction.nftContract.safeTransferFrom(
            address(this),
            _auction.creator,
            _auction.nftId,
            1,
            "0x00"
        );

        //close the auction state
        _auction.status = AuctionState.CLOSED;
    }

    function setMetawoodNFT(address _newMetawoodNFT)
        external
        ensureNonZeroAddress(_newMetawoodNFT)
        onlyOwner
    {
        metawoodNFT = IMetawoodNFT(_newMetawoodNFT);
    }

    function updateBiddingThreshold(uint256 _newBiddingThreshold) public onlyOwner {
        bidIncreaseThreshold = _newBiddingThreshold;
    }

    //Getters

    function getAuctionById(uint256 _auctionId) external view returns (Auction memory) {
        return _auctions[_auctionId];
    }

    function getHighestBid(uint256 _auctionId) external view returns (uint256, address) {
        Auction memory _auction = _auctions[_auctionId];
        return (_auction.highestBid, _auction.highestBidder);
    }

    function getAllAuctions() external view returns (Auction[] memory) {
        Auction[] memory auctions = new Auction[](_auctionCounter.current());
        for (uint256 i = 0; i < _auctionCounter.current(); i++) {
            auctions[i] = _auctions[i];
        }

        return auctions;
    }

    function getAllActiveAuctions() external view returns (Auction[] memory) {
        uint256 _activeCount = 0;

        for (uint256 i = 0; i < _auctionCounter.current(); i++) {
            if (_auctions[i].status == AuctionState.ACTIVE) {
                _activeCount++;
            }
        }

        Auction[] memory auctions = new Auction[](_activeCount);

        for (uint256 i = 0; i < _auctionCounter.current(); i++) {
            if (_auctions[i].status == AuctionState.ACTIVE) {
                auctions[_activeCount - 1] = _auctions[i];
                _activeCount--;
            }
        }

        return auctions;
    }
}
