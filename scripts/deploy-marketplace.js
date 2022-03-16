const {ethers} = require('hardhat');
const {saveAbi} = require('./utils');

const main = async () => {
  const MarketPlaceContract = await ethers.getContractFactory(
    'MetawoodMarketPlace'
  );
  const marketPlace = await MarketPlaceContract.deploy();

  await marketPlace.deployed();

  console.log('MarketPlace deployed to:', marketPlace.address);
  saveAbi('MetawoodMarketPlace', marketPlace);
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
