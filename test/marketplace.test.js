const { web3, network } = require("hardhat");
const { expect } = require("chai");

const { abi: nftABI, bytecode: nftByteCode } = require("../artifacts/contracts/MetawoodNft.sol/MetawoodNFT.json")
const { abi: marketPlaceABI, bytecode: marketPlaceByteCode } = require("../artifacts/contracts/MetawoodNFTMarketPlaceV1.sol/MetawoodNFTMarketPlaceV1.json");

describe("NFT-Marketplace-Test", () => {
    let accounts;
    let nftContractInstance;
    let marketPlaceContractInstance;

    context("Withdraw ERC20 / Withdraw Received Ethers", () => {
        before(async () => {
            accounts = await web3.eth.getAccounts();

            nftContractInstance = await new web3.eth.Contract(nftABI)
                .deploy({ data: nftByteCode, arguments: ["https://ipfs.metawood.io/"] })
                .send({ from: accounts[0] });

            marketPlaceContractInstance = await new web3.eth.Contract(marketPlaceABI)
                .deploy({ data: marketPlaceByteCode, arguments: [nftContractInstance.options.address] })
                .send({ from: accounts[0] });

            /**
             * mint MWT Tokens && send to marketplace contract
             * minting is not possible since **_mint** is internal function in ERC20 ABI
             * 
             * so, manually setting balance of contract to 10 ETH similar to transfer of tokens.
             */
            await network.provider.send(
                "hardhat_setBalance",
                [marketPlaceContractInstance.options.address, "0x1000000000000000"]
            );
        });

        it("Except owner, no one is able to withdraw", async () => {
            try {
                await marketPlaceContractInstance.methods.withdrawReceivedEther().send({
                    from: accounts[1]
                });
            } catch (e) {
                expect(e.message).to.include("Ownable: caller is not the owner");
            }
        });

        it("Owner is able to withdraw", async () => {
            const initialBalance = await web3.eth.getBalance(accounts[0]);

            const tx = await marketPlaceContractInstance.methods.withdrawReceivedEther().send({
                from: accounts[0],
            });
            let gasConsumerForTxn = (tx.effectiveGasPrice * tx.gasUsed);

            const afterBalance = await web3.eth.getBalance(accounts[0]);

            /**
             * since the `tx` is happening, but also receiving ethers from the `withdrawReceivedEther` function
             * afterBalance is greater than initialBalance
             */
            expect( parseFloat( web3.utils.fromWei(afterBalance, "ether") ) ).to.be.greaterThan( parseFloat( web3.utils.fromWei(initialBalance) ) );
        });
    });

    context("Create Listing", async () => {
        it("Able to create and fetch Listing", async () => {
            
        });
    });

    context("Get Open Listing", () => {
        it("Initially 0 listings", async () => {

        });

        it("After listing, should show correct listings", async () => {

        });
    });

    context("Get Latest Listing", () => {
        it("Initially 0 listings", async () => {

        });

        it("After listing, should show correct listings", async () => {

        });
    });

    context("Get All Listing", () => {
        it("Initially 0 listings", async () => {

        });

        it("After listing, should show correct listings", async () => {

        });
    });

    context("Change Listing price", () => {

    });

    context("Close Listing", () => {
        it("Able to close listing", async () => {

        });
    });

    context("Purchase NFT", () => {

    });


    it("Zero NFTs in account", async () => {
        const response = await marketPlaceContract.methods;
    });
})