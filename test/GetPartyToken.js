const { expect } = require("chai");
const { ethers } = require('hardhat');

async function deployGetPartyTokenFixture() {
    const initialSupply = ethers.utils.parseEther("1000000");  // 1,000,000 tokens
    const buyFeePercent = 3;  // 3% fee

    const [owner, otherAccount] = await ethers.getSigners();

    const GetPartyToken = await ethers.getContractFactory("GetPartyToken");
    const token = await GetPartyToken.deploy(initialSupply, buyFeePercent);

    return { token, initialSupply, buyFeePercent, owner, otherAccount };
}

describe("GetPartyToken", function () {
    describe("Deployment", function () {
        it("Should set the right initial supply", async function () {
            const { token, initialSupply } = await deployGetPartyTokenFixture();

            expect(await token.totalSupply()).to.equal(initialSupply);
        });

        it("Should assign the total supply of tokens to the owner", async function () {
            const { token, initialSupply, owner } = await deployGetPartyTokenFixture();

            expect(await token.balanceOf(owner.address)).to.equal(initialSupply);
        });

        it("Should set the right buy fee percent", async function () {
            const { token, buyFeePercent } = await deployGetPartyTokenFixture();

            expect(await token.buyFeePercent()).to.equal(buyFeePercent);
        });
    });

    describe("Buy Tokens", function () {
        it("Should let users buy tokens and deduct the fee", async function () {
            const { token, buyFeePercent, otherAccount } = await deployGetPartyTokenFixture();
            const purchaseAmount = ethers.utils.parseEther("1");  // 1 ETH
            const expectedFee = purchaseAmount.mul(buyFeePercent).div(100);
            const expectedTokens = purchaseAmount.sub(expectedFee);

            await otherAccount.sendTransaction({
                to: token.address,
                value: purchaseAmount
            });

            expect(await token.balanceOf(otherAccount.address)).to.equal(expectedTokens);
        });

        it("Should transfer the buy fee to the owner", async function () {
            const { token, buyFeePercent, owner, otherAccount } = await deployGetPartyTokenFixture();
            const purchaseAmount = ethers.utils.parseEther("1");
            const expectedFee = purchaseAmount.mul(buyFeePercent).div(100);

            await otherAccount.sendTransaction({
                to: token.address,
                value: purchaseAmount
            });

            expect(await ethers.provider.getBalance(token.address)).to.equal(expectedFee);
        });
    });

    describe("Fee Management", function () {
        it("Should allow the owner to change the buy fee percent", async function () {
            const { token, owner } = await deployGetPartyTokenFixture();
            const newBuyFeePercent = 5;

            await token.connect(owner).setBuyFeePercent(newBuyFeePercent);

            expect(await token.buyFeePercent()).to.equal(newBuyFeePercent);
        });

        it("Should prevent non-owners from changing the buy fee percent", async function () {
            const { token, otherAccount } = await deployGetPartyTokenFixture();
            const newBuyFeePercent = 5;

            await expect(
                token.connect(otherAccount).setBuyFeePercent(newBuyFeePercent)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });
    });
});
