const {ethers} = require('hardhat');
const {saveAbi} = require('./utils');

const main = async () => {
  const NftContract = await ethers.getContractFactory('MetawoodNft');
  const nftContract = await NftContract.deploy();

  await nftContract.deployed();

  console.log('Token deployed to:', nftContract.address);
  saveAbi('MetawoodNft', nftContract);
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
