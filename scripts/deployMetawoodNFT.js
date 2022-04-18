const { ethers } = require("hardhat");
const { saveAbi } = require("./utils");

const main = async () => {
  const MetawoodNFTContract = await ethers.getContractFactory("MetawoodNFT");
  const metawoodNFTContractInstance = await MetawoodNFTContract.deploy();

  await metawoodNFTContractInstance.deployed();
  console.log("Metawood NFT ERC1155 deployed at " + metawoodNFTContractInstance.address);
  await metawoodNFTContractInstance.deployTransaction.wait([(confirms = 6)]);

  console.log("MetawoodNFT deployed to:", metawoodNFTContractInstance.address);
  saveAbi("MetawoodNFT", metawoodNFTContractInstance);

  await hre.run("verify:verify", {
    address: metawoodNFTContractInstance.address,
    constructorArguments: [],
  });
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
