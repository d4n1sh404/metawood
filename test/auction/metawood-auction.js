const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");
const { keccak256 } = require("ethers/lib/utils");

let nftAuction;
let nftContract;
let deployer;
let user;
let userTwo;
let userThree;

describe.only("Metawood Auction", () => {
  before(async () => {
    deployer = (await ethers.getSigners())[0];
    user = (await ethers.getSigners())[1];
    userTwo = (await ethers.getSigners())[2];
    userThree = (await ethers.getSigners())[3];

    const NftContract = await ethers.getContractFactory("MetawoodNFT");
    nftContract = await NftContract.deploy("");

    await nftContract.deployed();

    const AuctionContract = await ethers.getContractFactory("MetawoodAuction");
    nftAuction = await AuctionContract.deploy(nftContract.address);

    await nftAuction.deployed();
  });

  it("Should register nftToken Contract on Auctoion Platform!", async function () {
    let setTx = await nftAuction.setMetawoodNFT(nftContract.address);
    let getTx = await nftAuction.metawoodNFT();
    expect(getTx).to.equal(nftContract.address);
  });

  it("Should grant minter role!", async function () {
    let role = keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE"));
    let tx = await nftContract.grantRole(role, user.address);
  });

  it("Should mint a new token!", async function () {
    let tx = await nftContract.connect(user).mint(user.address, 1, "http://testing", "0x00");
  });

  it("Minted token should have custom uri", async function () {
    let tx = await nftContract.uri(0);
    expect(tx).to.equal("http://testing");
  });

  it("User should have minted token!", async function () {
    let tx = await nftContract.balanceOf(user.address, 0);
    expect(BigNumber.from(tx)).to.be.equal(1);
  });

  it("User should be able to auction minted token!", async function () {
    let approveTx = await nftContract.connect(user).setApprovalForAll(nftAuction.address, true);
    let tx = await nftAuction
      .connect(user)
      .createAuction(0, ethers.utils.parseEther("100"), new Date() * 1000 + 60);
  });

  it("Auction should have been created!", async function () {
    let tx = await nftAuction.getAuctionById(0);
    expect(tx.id).to.be.equal(0); //listingId
    expect(tx.creator).to.be.equal(user.address); //creatorAddress
    expect(tx.nftId).to.be.equal(0); //tokenId
  });

  it("Should escrow the nft!", async function () {
    let transferCheck = await nftContract.balanceOf(user.address, 0);
    expect(transferCheck).to.be.equal(0);
    let escrowCheck = await nftContract.balanceOf(nftAuction.address, 0);
    expect(escrowCheck).to.be.equal(1);
  });

  it("Should get latest auctions!", async function () {
    let tx = await nftAuction.getAllAuctions();
    expect(tx.length).to.be.equal(1);
  });

  // it("User Should get his open listings!", async function () {
  //   let tx = await marketPlace.connect(user).getOpenListings(user.address);
  //   expect(tx.length).to.be.equal(1);
  // });

  it("Should get all active auctions!", async function () {
    let tx = await nftAuction.getAllActiveAuctions();
    expect(tx.length).to.be.equal(1);
  });

  it("Bid should be made!", async function () {
    let tx = await nftAuction
      .connect(userTwo)
      .makeBid(0, { value: ethers.utils.parseEther("120") });
  });

  it("Should escrow the bid amount!", async function () {
    let escrowCheck = await ethers.provider.getBalance(nftAuction.address);
    expect(escrowCheck).to.be.equal(ethers.utils.parseEther("120"));
  });

  it("Hightest Bid should be made!", async function () {
    let tx = await nftAuction
      .connect(userThree)
      .makeBid(0, { value: ethers.utils.parseEther("150") });
  });

  it("Should escrow the highest bid only!", async function () {
    let escrowCheck = await ethers.provider.getBalance(nftAuction.address);
    expect(escrowCheck).to.be.equal(ethers.utils.parseEther("150"));
  });

  /*

  it("User should be able to close  his listing!", async function () {
    let tx = await marketPlace.connect(userTwo).closeListing(1);
  });
  */
});
