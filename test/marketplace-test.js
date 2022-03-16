const {ethers} = require('hardhat');


describe('Marketplace Contract', function () {
  it('Should depoly the marketplace', async function () {
    // eslint-disable-next-line no-undef
    const MarketPlaceContract = await ethers.getContractFactory(
      'MetawoodMarketPlace'
    );
    const marketPlace = await MarketPlaceContract.deploy();

    await marketPlace.deployed();
  });
});
