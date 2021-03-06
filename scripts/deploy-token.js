const {ethers} = require('hardhat');
const {saveAbi} = require('./utils');

const main = async () => {
  const TokenContract = await ethers.getContractFactory(
    'MetawoodToken'
  );
  const token = await TokenContract.deploy();

  await token.deployed();

  console.log('Token deployed to:', token.address);
  saveAbi('MetawoodToken', token);
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
