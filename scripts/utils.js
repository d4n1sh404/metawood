const fs = require("fs");
const path = require("path");
const { artifacts, network } = require("hardhat");

const contractsDir = path.join(__dirname, "/../src/abis");

const saveAbi = (name, contract) => {
  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  const artifact = artifacts.readArtifactSync(name);

  fs.writeFileSync(
    `${contractsDir}/${name}.json`,
    JSON.stringify(
      {
        name,
        network: network.name,
        address: contract.address,
        abi: artifact.abi,
      },
      null,
      2
    )
  );
};

module.exports = {
  saveAbi,
};
