const { ethers } = require("hardhat");
const { saveAbi } = require("./utils");

const main = async () => {
  const MetawoodNFTContract = await ethers.getContractFactory("MetawoodNFT");
  const metawoodNFTContractInstance = await MetawoodNFTContract.deploy("");

  await metawoodNFTContractInstance.deployed();
  console.log("Metawood NFT ERC1155 deployed at " + metawoodNFTContractInstance.address);
  await metawoodNFTContractInstance.deployTransaction.wait([(confirms = 6)]);

  await hre.run("verify:verify", {
    address: metawoodNFTContractInstance.address,
    constructorArguments: [""],
  });

  const MarketPlaceContract = await ethers.getContractFactory("MetawoodNFTMarketPlaceV1");
  const marketPlaceContractInstance = await MarketPlaceContract.deploy(
    metawoodNFTContractInstance.address
  );
  await marketPlaceContractInstance.deployed();
  console.log("Marketplace deployed to:", marketPlaceContractInstance.address);
  await marketPlaceContractInstance.deployTransaction.wait([(confirms = 6)]);

  await hre.run("verify:verify", {
    address: marketPlaceContractInstance.address,
    constructorArguments: [metawoodNFTContractInstance.address],
  });

  await metawoodNFTContractInstance.setMetawoodMarketPlace(marketPlaceContractInstance.address);

  saveAbi("MetawoodNFT", metawoodNFTContractInstance);
  saveAbi("MetawoodNFTMarketPlaceV1", marketPlaceContractInstance);
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
