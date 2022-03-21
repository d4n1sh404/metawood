const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

let marketPlace;
let nftContract;
let nativeToken;
let deployer;
let user;

describe("Metawood Marketplace", () => {
  before(async () => {
    deployer = (await ethers.getSigners())[0];
    user = (await ethers.getSigners())[1];

    const NftContract = await ethers.getContractFactory("MetawoodNft");
    nftContract = await NftContract.deploy();

    await nftContract.deployed();

    const TokenContract = await ethers.getContractFactory("MetawoodToken");
    nativeToken = await TokenContract.deploy();

    const MarketPlaceContract = await ethers.getContractFactory("MetawoodMarketPlace");
    marketPlace = await MarketPlaceContract.deploy(nftContract.address);

    await nativeToken.deployed();
    await marketPlace.deployed();
  });

  it("Faucet should be active!", async function () {
    let tx = await nativeToken.requestToken(user.address, BigNumber.from("100000000"));

    let tx2 = await nativeToken.balanceOf(user.address);
    expect(BigNumber.from(tx2)).to.be.equal(BigNumber.from("100000000"));
  });

  it("Should register native Token!", async function () {
    let tx = await marketPlace.addSupportedToken("native", nativeToken.address);
  });

  it("Should register marketplace on nftToken!", async function () {
    let tx = await nftContract.setMarketPlace(marketPlace.address);
  });

  it("Should mint a new token!", async function () {
    let tx = await nftContract.mint(deployer.address, 1, "http://testing", "0x00");
  });

  it("User should have minted token!", async function () {
    let tx = await nftContract.balanceOf(deployer.address, 1);
    expect(BigNumber.from(tx)).to.be.equal(1);
  });

  it("User should be able to list minted token!", async function () {
    let tx = await marketPlace.createListing(1, 100);
  });

  it("Listing should have been created!", async function () {
    let tx = await marketPlace.getListing(1);
    expect(BigNumber.from(tx[0])).to.be.equal(1); //listingId
    expect(tx[1]).to.be.equal(deployer.address); //creatorAddress
    expect(BigNumber.from(tx[2])).to.be.equal(1); //tokenId
    expect(BigNumber.from(tx[3])).to.be.equal(100); //lisingPrice
  });

  it("Should get latest listings!", async function () {
    let tx = await marketPlace.getLatestListings(3);
    expect(tx.length).to.be.equal(3);
  });

  it("Should list owned tokens!", async function () {
    let tx = await marketPlace.getOwnedTokens();
    expect(BigNumber.from(tx[0])).to.be.equal(1); //tokenId
  });

  it("Listing should be bought!", async function () {
    // console.log(await marketPlace.isApprovedForAll(deployer.address,marketPlace.address));
    let approve = await nativeToken
      .connect(user)
      .approve(marketPlace.address, ethers.constants.MaxUint256);
    let tx = await marketPlace.connect(user).buyNft(1);
    let tx2 = await nftContract.balanceOf(user.address, 1);
    expect(BigNumber.from(tx2)).to.be.equal(1);
  });

  it("Should register a new User!", async function () {
    let tx = await marketPlace.addUser(user.address, "datauri");
  });

  it("Should get the registered User!", async function () {
    let tx = await marketPlace.getUser(user.address);
    expect(tx.data == "datauri");
  });
});