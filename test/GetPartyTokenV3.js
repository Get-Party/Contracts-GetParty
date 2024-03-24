const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("GetPartyTokenV3", function () {
    let GetPartyTokenV3 = null;
    let getPartyTokenV3 = null;
    let owner, addr1, addr2 = null;

    // totalSupply = 1_000_000_000 * (10 ** 9)
    const totalSupply = 1000000000000000000n;

    beforeEach(async function () {
        const IterableMapping = await ethers.getContractFactory("IterableMapping");
        const iterableMapping = await IterableMapping.deploy();
        GetPartyTokenV3 = await ethers.getContractFactory("GetPartyTokenV3", {
            libraries: {
                IterableMapping: iterableMapping,
            },
        });
        [owner, addr1, addr2, _] = await ethers.getSigners();
        getPartyTokenV3 = await GetPartyTokenV3.deploy();

        // Enable Trading.
        await getPartyTokenV3.enableTrading();
    });

    describe('Token properties', function () {
        it("Should return the total supply", async function () {
            expect(await getPartyTokenV3.totalSupply()).to.equal(totalSupply);
        });

        it("Should return the balance of the owner", async function () {
            expect(await getPartyTokenV3.balanceOf(owner.address)).to.equal(totalSupply);
        });

        it('Should set the right owner', async function () {
            expect(await getPartyTokenV3.owner()).to.equal(owner.address);
        });

        it('Should assign the total supply of tokens to the owner', async function () {
            const ownerBalance = await getPartyTokenV3.balanceOf(owner.address);
            expect(await getPartyTokenV3.totalSupply()).to.equal(ownerBalance);
        });
    });

    describe('Token transfers', function () {
        it('Should transfer tokens between accounts', async function () {
            await getPartyTokenV3.transfer(addr1.address, 50);
            const addr1Balance = await getPartyTokenV3.balanceOf(addr1.address);
            expect(addr1Balance).to.equal(50);

            await getPartyTokenV3.connect(addr1).transfer(addr2.address, 50);
            const addr2Balance = await getPartyTokenV3.balanceOf(addr2.address);
            expect(addr2Balance).to.equal(50);
        });

        it('Should fail if sender doesn’t have enough tokens', async function () {
            const initialOwnerBalance = await getPartyTokenV3.balanceOf(owner.address);
            await expect(
                getPartyTokenV3.connect(addr1).transfer(owner.address, 1)
            ).to.be.revertedWith('ERC20: transfer amount exceeds balance');

            expect(await getPartyTokenV3.balanceOf(owner.address)).to.equal(
                initialOwnerBalance
            );
        });

        it('Should update balances after transfers', async function () {
            const initialOwnerBalance = await getPartyTokenV3.balanceOf(owner.address);

            await getPartyTokenV3.transfer(addr1.address, 100);
            await getPartyTokenV3.transfer(addr2.address, 50);

            const finalOwnerBalance = await getPartyTokenV3.balanceOf(owner.address);
            expect(finalOwnerBalance).to.equal(initialOwnerBalance - BigInt(150));

            const addr1Balance = await getPartyTokenV3.balanceOf(addr1.address);
            expect(addr1Balance).to.equal(BigInt(100));

            const addr2Balance = await getPartyTokenV3.balanceOf(addr2.address);
            expect(addr2Balance).to.equal(BigInt(50));
        });
    });

    describe('Trading', function () {
        it('Should return error when trading is enabled and try to enable again', async function () {
            await expect(getPartyTokenV3.enableTrading()).to.be.revertedWith('Trading already enabled.');
        });

        it('Should allow trading after it is enabled', async function () {
            await getPartyTokenV3.transfer(addr1.address, 50);
            expect(await getPartyTokenV3.balanceOf(addr1.address)).to.equal(50);
        });
    });

    describe('Treasury Wallet', function () {
        it('Should not allow to set the treasury wallet to the zero address', async function () {
            await expect(
                getPartyTokenV3.changeTreasuryWallet(ethers.ZeroAddress)
            ).to.be.revertedWith('Marketing wallet cannot be the zero address');
        });

        it('Should not allow to set the treasury wallet to a contract address', async function () {
            const contractAddress = await getPartyTokenV3.getAddress();
            await expect(
                getPartyTokenV3.changeTreasuryWallet(contractAddress)
            ).to.be.revertedWith('Marketing wallet cannot be a contract');
        });

        it('Should allow to change the treasury wallet', async function () {
            await getPartyTokenV3.changeTreasuryWallet(addr1.address);
            expect(await getPartyTokenV3.treasuryWallet()).to.equal(addr1.address);
        });
    });
});