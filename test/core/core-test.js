const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");
const chai = require("chai");
chai.use(solidity);
const { expect } = chai;
const { parseEther, keccak256 } = require("ethers/lib/utils");
const { BigNumber } = require("ethers");
const { MaxUint256, AddressZero } = ethers.constants;

describe("Metawood marketplace Core test cases", function () {
  before(async function () {
    this.signers = await ethers.getSigners();
    this.deployer = this.signers[0];
    this.user1 = this.signers[1];
    this.user2 = this.signers[2];
    this.openSeaProxyAddress = "0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101";

    const MetawoodNFTContract = await ethers.getContractFactory("MetawoodNFT");
    this.metawoodNFTContractInstance = await MetawoodNFTContract.deploy("");

    await this.metawoodNFTContractInstance.deployed();
    console.log("MetawoodNFT ERC1155 deployed at " + this.metawoodNFTContractInstance.address);

    const MarketPlaceContract = await ethers.getContractFactory("MetawoodNFTMarketPlaceV1");
    this.marketPlaceContractInstance = await MarketPlaceContract.deploy(
      this.metawoodNFTContractInstance.address
    );
    await this.marketPlaceContractInstance.deployed();
    console.log("Marketplace deployed to:", this.marketPlaceContractInstance.address);
  });

  it("should set correct state variables for MetawoodNFT Contract", async function () {
    const minterRole = await this.metawoodNFTContractInstance.MINTER_ROLE();
    const adminRole = await this.metawoodNFTContractInstance.DEFAULT_ADMIN_ROLE();
    let metawoodMarketPlace = await this.metawoodNFTContractInstance.metawoodMarketPlace();
    const tokenCount = await this.metawoodNFTContractInstance.getTokenCount();
    const owner = await this.metawoodNFTContractInstance.owner();
    const doesAdminHaveAdminRole = await this.metawoodNFTContractInstance.hasRole(adminRole, owner);
    const doesAdminHaveMinterRole = await this.metawoodNFTContractInstance.hasRole(
      minterRole,
      owner
    );
    const isPaused = await this.metawoodNFTContractInstance.paused();

    expect(minterRole).to.equal(keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE")));
    expect(metawoodMarketPlace).to.equal(AddressZero);
    expect(tokenCount).to.equal(0);
    expect(owner).to.equal(this.deployer.address);
    expect(isPaused).to.equal(false);
    expect(doesAdminHaveAdminRole).to.equal(true);
    expect(doesAdminHaveMinterRole).to.equal(true);
  });

  it("should set marketplace correctly and auotmatic approve for marketplace address", async function () {
    await expect(
      this.metawoodNFTContractInstance.setMetawoodMarketPlace(AddressZero)
    ).to.be.revertedWith("MetawoodNFT: No zero address");
    await this.metawoodNFTContractInstance.setMetawoodMarketPlace(
      this.marketPlaceContractInstance.address
    );
    metawoodMarketPlace = await this.metawoodNFTContractInstance.metawoodMarketPlace();
    expect(metawoodMarketPlace).to.equal(this.marketPlaceContractInstance.address);

    const isApprovedForAllMarketPlace1 = await this.metawoodNFTContractInstance.isApprovedForAll(
      this.user1.address,
      metawoodMarketPlace
    );
    const isApprovedForAllMarketPlace2 = await this.metawoodNFTContractInstance.isApprovedForAll(
      this.user2.address,
      metawoodMarketPlace
    );
    expect(isApprovedForAllMarketPlace1).to.equal(true);
    expect(isApprovedForAllMarketPlace2).to.equal(true);
    const isApprovedForAllOpensea1 = await this.metawoodNFTContractInstance.isApprovedForAll(
      this.user1.address,
      this.openSeaProxyAddress
    );
    const isApprovedForAllOpensea2 = await this.metawoodNFTContractInstance.isApprovedForAll(
      this.user2.address,
      this.openSeaProxyAddress
    );
    expect(isApprovedForAllOpensea1).to.equal(true);
    expect(isApprovedForAllOpensea2).to.equal(true);
  });

  it("should grant minter roles to whitelisted minters", async function () {
    const minterRole = await this.metawoodNFTContractInstance.MINTER_ROLE();
    const adminRole = await this.metawoodNFTContractInstance.DEFAULT_ADMIN_ROLE();
    const doesUser1HaveAdminRole = await this.metawoodNFTContractInstance.hasRole(
      adminRole,
      this.user1.address
    );
    let doesUser1HaveMinterRole = await this.metawoodNFTContractInstance.hasRole(
      minterRole,
      this.user1.address
    );

    expect(doesUser1HaveAdminRole).to.equal(false);
    expect(doesUser1HaveMinterRole).to.equal(false);

    await this.metawoodNFTContractInstance.grantRole(minterRole, this.user1.address);

    doesUser1HaveMinterRole = await this.metawoodNFTContractInstance.hasRole(
      minterRole,
      this.user1.address
    );
    expect(doesUser1HaveMinterRole).to.equal(true);
  });

  it("non whitelisted minters should not be able to mint NFTs", async function () {
    await expect(
      this.metawoodNFTContractInstance
        .connect(this.user2)
        .mint(this.user2.address, 1, "http://testing", "0x00")
    ).to.be.reverted;
  });

  it("whitelisted minters should be able to mint NFTs", async function () {
    await expect(
      this.metawoodNFTContractInstance
        .connect(this.user1)
        .mint(AddressZero, 1, "http://testing", "0x00")
    ).to.be.revertedWith("MetawoodNFT: No zero address");
    await expect(
      this.metawoodNFTContractInstance
        .connect(this.user1)
        .mint(this.user1.address, 0, "http://testing", "0x00")
    ).to.be.revertedWith("MetawoodNFT: invalid amount parameter");
    await this.metawoodNFTContractInstance
      .connect(this.user1)
      .mint(this.user1.address, 1, "http://testing", "0x00");

    const tokenCount = await this.metawoodNFTContractInstance.getTokenCount();
    const tokenUri = await this.metawoodNFTContractInstance.uri(0);
    const userstokenBalance = await this.metawoodNFTContractInstance.balanceOf(
      this.user1.address,
      0
    );
    const exists = await this.metawoodNFTContractInstance.exists(0);
    const totalSupply = await this.metawoodNFTContractInstance.totalSupply(0);

    expect(tokenUri).to.equal("http://testing");
    expect(tokenCount).to.equal(1);
    expect(userstokenBalance).to.equal(1);
    expect(exists).to.equal(true);
    expect(totalSupply).to.equal(1);
  });

  it("Admin should be able to change tokenURIs in emergency", async function () {
    let tokenUri = await this.metawoodNFTContractInstance.uri(0);
    expect(tokenUri).to.equal("http://testing");

    await expect(
      this.metawoodNFTContractInstance.connect(this.user1).setTokenURI(0, "http://testing0")
    ).to.be.revertedWith("Ownable: caller is not the owner");
    await this.metawoodNFTContractInstance.setTokenURI(0, "http://testing0");

    tokenUri = await this.metawoodNFTContractInstance.uri(0);
    expect(tokenUri).to.equal("http://testing0");
  });

  it("Contract is not paused. NFT Transfer should work", async function () {
    let isPaused = await this.metawoodNFTContractInstance.paused();
    expect(isPaused).to.equal(false);
    await this.metawoodNFTContractInstance
      .connect(this.user1)
      .safeTransferFrom(this.user1.address, this.user2.address, 0, 1, "0x00");
  });

  it("Contract is paused. NFT Transfer shouldn't work", async function () {
    await expect(this.metawoodNFTContractInstance.connect(this.user1).pause()).to.be.revertedWith(
      "Ownable: caller is not the owner"
    );
    await this.metawoodNFTContractInstance.pause();

    isPaused = await this.metawoodNFTContractInstance.paused();
    expect(isPaused).to.equal(true);

    await expect(
      this.metawoodNFTContractInstance
        .connect(this.user2)
        .safeTransferFrom(this.user2.address, this.user1.address, 0, 1, "0x00")
    ).to.be.revertedWith("Pausable: paused");
  });

  it("Contract back to default unpaused mode. NFT Transfer should work", async function () {
    await this.metawoodNFTContractInstance.unpause();
    await this.metawoodNFTContractInstance
      .connect(this.user2)
      .safeTransferFrom(this.user2.address, this.user1.address, 0, 1, "0x00");

    isPaused = await this.metawoodNFTContractInstance.paused();
    expect(isPaused).to.equal(false);
  });

  it("Batch Mint should work", async function () {
    await expect(
      this.metawoodNFTContractInstance
        .connect(this.user1)
        .mintBatch(AddressZero, [1], ["http://testing"], "0x00")
    ).to.be.revertedWith("MetawoodNFT: No zero address");
    await expect(
      this.metawoodNFTContractInstance
        .connect(this.user1)
        .mintBatch(this.user1.address, [1, 1], ["http://testing"], "0x00")
    ).to.be.revertedWith("MetawoodNFT: tokenUrls and amounts length mismatch");
    await expect(
      this.metawoodNFTContractInstance
        .connect(this.user1)
        .mintBatch(this.user1.address, [0, 1], ["http://testing", "http://testing"], "0x00")
    ).to.be.revertedWith("MetawoodNFT: invalid amount parameter");
    await this.metawoodNFTContractInstance
      .connect(this.user1)
      .mintBatch(this.user1.address, [1, 1], ["http://testing", "http://testing"], "0x00");

    const tokenCount = await this.metawoodNFTContractInstance.getTokenCount();
    const tokenUri = await this.metawoodNFTContractInstance.uri(2);
    const userstokenBalance = await this.metawoodNFTContractInstance.balanceOf(
      this.user1.address,
      2
    );
    const exists = await this.metawoodNFTContractInstance.exists(2);
    const totalSupply = await this.metawoodNFTContractInstance.totalSupply(2);

    expect(tokenUri).to.equal("http://testing");
    expect(tokenCount).to.equal(3);
    expect(userstokenBalance).to.equal(1);
    expect(exists).to.equal(true);
    expect(totalSupply).to.equal(1);

    //Sending NFTs to user2 for future tests
    await this.metawoodNFTContractInstance
      .connect(this.user1)
      .safeBatchTransferFrom(this.user1.address, this.user2.address, [1, 2], [1, 1], "0x00");
  });

  it.skip("Burn and BurnBatch should work", async function () {
    await this.metawoodNFTContractInstance
      .connect(this.user1)
      .burnBatch(this.user1.address, [1, 2], [1, 1]);

    const userstokenBalance = await this.metawoodNFTContractInstance.balanceOf(
      this.user1.address,
      2
    );
    const exists = await this.metawoodNFTContractInstance.exists(2);
    const totalSupply = await this.metawoodNFTContractInstance.totalSupply(2);

    expect(userstokenBalance).to.equal(0);
    expect(exists).to.equal(false);
    expect(totalSupply).to.equal(0);
  });

  it("should set correct state variables for MetawoodMarketplaceV1 Contract", async function () {
    const metawoodNFT = await this.marketPlaceContractInstance.metawoodNFT();
    const isPaused = await this.marketPlaceContractInstance.paused();
    expect(metawoodNFT).to.equal(this.metawoodNFTContractInstance.address);
    expect(isPaused).to.equal(false);
  });

  it("should be able to list minted token!", async function () {
    await expect(
      this.marketPlaceContractInstance.connect(this.user1).createListing(10, 1)
    ).to.be.revertedWith("MetawoodMarketplaceV1: tokenId is not minted");
    await expect(
      this.marketPlaceContractInstance.connect(this.user1).createListing(1, 0)
    ).to.be.revertedWith("MetawoodMarketplaceV1: Token Not Owned!");
    await expect(
      this.marketPlaceContractInstance.connect(this.user1).createListing(0, 0)
    ).to.be.revertedWith("MetawoodMarketplaceV1: Price must be at least 1 wei");

    //No listing has been created for this tokenId before
    await this.marketPlaceContractInstance.connect(this.user1).createListing(0, parseEther("0.2"));

    const listingCount = await this.marketPlaceContractInstance.getListingCount();
    const userstokenBalance = await this.metawoodNFTContractInstance.balanceOf(
      this.user1.address,
      0
    );
    const listing = await this.marketPlaceContractInstance.getListing(0);
    expect(listing.seller).to.equal(this.user1.address);
    expect(listing.tokenPrice).to.equal(parseEther("0.2"));
    expect(listing.tokenId).to.equal(0);
    expect(listing.listingId).to.equal(0);
    expect(listing.status).to.equal(0);
    expect(listingCount).to.equal(1);
    expect(userstokenBalance).to.equal(1);
  });

  it("should not be able to create listing for same minted token even existing listng is open", async function () {
    await expect(
      this.marketPlaceContractInstance.connect(this.user1).createListing(0, parseEther("0.2"))
    ).to.be.revertedWith("MetawoodMarketplaceV1: Listing already exists for this token");

    await this.metawoodNFTContractInstance
      .connect(this.user1)
      .safeTransferFrom(this.user1.address, this.user2.address, 0, 1, "0x00");

    await expect(
      this.marketPlaceContractInstance.connect(this.user1).createListing(0, parseEther("0.2"))
    ).to.be.revertedWith("MetawoodMarketplaceV1: Token Not Owned");

    await this.marketPlaceContractInstance.connect(this.user2).createListing(0, parseEther("0.3"));
    await expect(
      this.marketPlaceContractInstance.connect(this.user1).changeListingPrice(0, parseEther("0.3"))
    ).to.be.revertedWith("MetawoodMarketplaceV1: Token Not Owned");

    const newListing = await this.marketPlaceContractInstance.getListing(1);
    const listingCount = await this.marketPlaceContractInstance.getListingCount();
    const userstokenBalance = await this.metawoodNFTContractInstance.balanceOf(
      this.user2.address,
      0
    );
    expect(newListing.seller).to.equal(this.user2.address);
    expect(newListing.tokenPrice).to.equal(parseEther("0.3"));
    expect(newListing.tokenId).to.equal(0);
    expect(newListing.listingId).to.equal(1);
    expect(newListing.status).to.equal(0);
    expect(listingCount).to.equal(2);
    expect(userstokenBalance).to.equal(1);
  });
});
