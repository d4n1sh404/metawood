/*const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");
const { keccak256 } = require("ethers/lib/utils");

let marketPlace;
let nftContract;
let deployer;
let user;
let userTwo;

describe("Metawood Marketplace", () => {
  before(async () => {
    deployer = (await ethers.getSigners())[0];
    user = (await ethers.getSigners())[1];
    userTwo = (await ethers.getSigners())[2];

    const NftContract = await ethers.getContractFactory("MetawoodNFT");
    nftContract = await NftContract.deploy("");

    await nftContract.deployed();

    const MarketPlaceContract = await ethers.getContractFactory("MetawoodNFTMarketPlaceV1");
    marketPlace = await MarketPlaceContract.deploy(nftContract.address);

    await marketPlace.deployed();
  });


  it("Should register marketplace on nftToken Contract!", async function () {
    let tx = await nftContract.setMetawoodMarketPlace(marketPlace.address);
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


  it("User should be able to list minted token!", async function () {
    let tx = await marketPlace.connect(user).createListing(0, 1);
  });


  it("Listing should have been created!", async function () {
    let tx = await marketPlace.getListing(0);
    expect(tx.listingId).to.be.equal(0); //listingId
    expect(tx.seller).to.be.equal(user.address); //creatorAddress
    expect(tx.tokenId).to.be.equal(0); //tokenId
    expect(tx.tokenPrice).to.be.equal(1); //lisingPrice
  });


  it("Should get latest listings!", async function () {
    let tx = await marketPlace.getLatestListings(3);
    expect(tx.length).to.be.equal(3);
  });


  it("User Should get his open listings!", async function () {
    let tx = await marketPlace.connect(user).getOpenListings(user.address);
    expect(tx.length).to.be.equal(1);
  });


  it("Should get all open listings!", async function () {
    let tx = await marketPlace.getAllOpenListings();
    expect(tx.length).to.be.equal(1);
  });


  it("Should list owned tokens!", async function () {
    let tx = await marketPlace.connect(user).getOwnedTokens(user.address);
    expect(BigNumber.from(tx[0])).to.be.equal(0); //tokenId
  });

  it("Listing should be bought!", async function () {
    let tx = await marketPlace.connect(userTwo).purchaseNFT(0,{value: 1});
    let tx2 = await nftContract.balanceOf(userTwo.address, 0);
    expect(BigNumber.from(tx2)).to.be.equal(1); 
  });


  it("Buyer should be able to list bought token!", async function () {
    let tx = await marketPlace.connect(userTwo).createListing(0, 2);
  });

  it("User should be able to close  his listing!", async function () {
    let tx = await marketPlace.connect(userTwo).closeListing(1);
  });


});
*/
