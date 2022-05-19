const hre = require("hardhat");
const { ethers } = require("hardhat");
const { saveAbi } = require("./utils");
const metawoodNft = require("../src/abis/MetawoodNFT.json");

const main = async () => {
  const MetawoodAuctionContract = await ethers.getContractFactory("MetawoodAuction");
  const metawoodAuctionContractInstance = await MetawoodAuctionContract.deploy(metawoodNft.address);

  await metawoodAuctionContractInstance.deployed();
  console.log("Metawood Auction deployed at " + metawoodAuctionContractInstance.address);

  saveAbi("MetawoodAuction", metawoodAuctionContractInstance);

  const polygonScanNetworks = ["mumbai", "matic"];
  let networkName = hre?.network?.name;

  if (polygonScanNetworks.includes(networkName)) {
    await metawoodAuctionContractInstance.deployTransaction.wait([(confirms = 6)]);

    await hre.run("verify:verify", {
      address: metawoodAuctionContractInstance.address,
      constructorArguments: [],
    });
  }
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
