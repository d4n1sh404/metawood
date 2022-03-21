const { ethers } = require("hardhat");
const { saveAbi } = require("./utils");

const main = async () => {
  const NftContract = await ethers.getContractFactory("MetawoodNft");
  nftContract = await NftContract.deploy();

  await nftContract.deployed();

  const TokenContract = await ethers.getContractFactory("MetawoodToken");
  nativeToken = await TokenContract.deploy();

  const MarketPlaceContract = await ethers.getContractFactory("MetawoodMarketPlace");
  marketPlace = await MarketPlaceContract.deploy(nftContract.address);

  console.log("Token deployed to:", nativeToken.address);
  console.log("Nft deployed to:", nftContract.address);
  console.log("Marketplace deployed to:", marketPlace.address);

  saveAbi("MetawoodNft", nftContract);
  saveAbi("MetawoodToken", nativeToken);
  saveAbi("MetawoodMarketPlace", marketPlace);

  await nativeToken.deployed();
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
