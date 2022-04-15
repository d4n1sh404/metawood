const { ethers } = require("hardhat");
const { saveAbi } = require("./utils");

const main = async () => {
  const NftContract = await ethers.getContractFactory("MetawoodNFT");
  nftContract = await NftContract.deploy("");

  await nftContract.deployed();

  const MarketPlaceContract = await ethers.getContractFactory("MetawoodNFTMarketPlaceV1");
  marketPlace = await MarketPlaceContract.deploy(nftContract.address);

  console.log("Nft deployed to:", nftContract.address);
  console.log("Marketplace deployed to:", marketPlace.address);

  await nftContract.setMetawoodMarketPlace(marketPlace.address);


  saveAbi("MetawoodNFT", nftContract);
  saveAbi("MetawoodNFTMarketPlaceV1", marketPlace);

  await marketPlace.deployed();
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
