const {expect} = require('chai');
const {ethers} = require('hardhat');
const {BigNumber} = require('ethers');

let marketPlace;
let nativeToken;
let deployer;
let user;


describe('Metawood Token Contract', () => {
  before(async () => {


    deployer = (await ethers.getSigners())[0];
    user = (await ethers.getSigners())[1];

    const TokenContract = await ethers.getContractFactory('MetawoodToken');
    nativeToken = await TokenContract.deploy();

    await nativeToken.deployed();
  });

  it('Faucet should be active!', async function () {
    let tx = await nativeToken.requestToken(user.address,BigNumber.from("1000"));
    let tx2 = await nativeToken.balanceOf(user.address);
    expect(BigNumber.from(tx2)).to.be.equal(BigNumber.from("1000"));
  });

});

describe('Marketplace Contract', function () {
  before(async () => {
    const MarketPlaceContract = await ethers.getContractFactory(
      'MetawoodMarketPlace'
    );
    marketPlace = await MarketPlaceContract.deploy();

    await marketPlace.deployed();
  });

  it('Should register native Token!', async function () {
    let tx = await marketPlace.addSupportedToken('native', nativeToken.address);
  });

  it('Should mint a new token!', async function () {
    let tx = await marketPlace.mint(
      deployer.address,
      1,
      'http://testing',
      '0x00'
    );
  });

  it('User should have minted token!', async function () {
    let tx = await marketPlace.balanceOf(deployer.address, 1);
    expect(BigNumber.from(tx)).to.be.equal(1);
  });

  it('User should be able to list minted token!', async function () {
    let tx = await marketPlace.createListing(1, 100);
  });

  it('Listing should have been created!', async function () {
    let tx = await marketPlace.getListing(1);
    expect(BigNumber.from(tx[0])).to.be.equal(1); //listingId
    expect(tx[1]).to.be.equal(deployer.address); //creatorAddress
    expect(BigNumber.from(tx[2])).to.be.equal(1); //tokenId
    expect(BigNumber.from(tx[3])).to.be.equal(100); //lisingPrice
  });

  it('Should get latest listings!', async function () {
    let tx = await marketPlace.getLatestListings(3);
    expect(tx.length).to.be.equal(3);
  });

  it('Should list owned tokens!', async function () {
    let tx = await marketPlace.getOwnedTokens();
    expect(BigNumber.from(tx[0])).to.be.equal(1); //tokenId
  });

  it('Listing should be bought!', async function () {
    let tx = await marketPlace.connect(user).buyNft(1);
    console.log(tx)
  });
});
