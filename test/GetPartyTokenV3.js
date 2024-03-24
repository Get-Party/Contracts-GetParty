const { ethers, BigNumber } = require("hardhat");
const { expect } = require("chai");

describe("GetPartyTokenV3", function () {
    let GetPartyTokenV3 = null;
    let getPartyTokenV3 = null;
    let owner, addr1, addr2 = null;

    // totalSupply = 1_000_000_000 * (10 ** 9)
    const totalSupply = 100000000000000000n;

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


    // function swapAndSendDividends(uint256 amount) private {
    //     address[] memory path = new address[](2);
    //     path[0] = uniswapV2Router.WETH();
    //     path[1] = rewardToken;

    //     uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
    //         value: amount
    //     }(0, path, address(this), block.timestamp);

    //     uint256 balanceRewardToken = IERC20(rewardToken).balanceOf(
    //         address(this)
    //     );
    //     bool success = IERC20(rewardToken).transfer(
    //         address(dividendTracker),
    //         balanceRewardToken
    //     );

    //     if (success) {
    //         dividendTracker.distributeDividends(balanceRewardToken);
    //         emit SendDividends(balanceRewardToken);
    //     }
    // }

    // function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
    //     require(
    //         newAmount > totalSupply() / 100_000,
    //         "SwapTokensAtAmount must be greater than 0.001% of total supply"
    //     );
    //     swapTokensAtAmount = newAmount;
    // }

    // function setSwapEnabled(bool _enabled) external onlyOwner {
    //     require(swapEnabled != _enabled, "swapEnabled already at this state.");
    //     swapEnabled = _enabled;
    // }

    // function updateGasForProcessing(uint256 newValue) public onlyOwner {
    //     require(
    //         newValue >= 200_000 && newValue <= 500_000,
    //         "gasForProcessing must be between 200,000 and 500,000"
    //     );
    //     require(
    //         newValue != gasForProcessing,
    //         "Cannot update gasForProcessing to same value"
    //     );
    //     emit GasForProcessingUpdated(newValue, gasForProcessing);
    //     gasForProcessing = newValue;
    // }

    // function updateMinimumBalanceForDividends(
    //     uint256 newMinimumBalance
    // ) external onlyOwner {
    //     dividendTracker.updateMinimumTokenBalanceForDividends(
    //         newMinimumBalance
    //     );
    // }

    // function updateClaimWait(uint256 newClaimWait) external onlyOwner {
    //     require(
    //         newClaimWait >= 3_600 && newClaimWait <= 86_400,
    //         "claimWait must be updated to between 1 and 24 hours"
    //     );
    //     dividendTracker.updateClaimWait(newClaimWait);
    // }

    // function getClaimWait() external view returns (uint256) {
    //     return dividendTracker.claimWait();
    // }

    // function getTotalDividendsDistributed() external view returns (uint256) {
    //     return dividendTracker.totalDividendsDistributed();
    // }

    // function withdrawableDividendOf(
    //     address account
    // ) public view returns (uint256) {
    //     return dividendTracker.withdrawableDividendOf(account);
    // }

    // function dividendTokenBalanceOf(
    //     address account
    // ) public view returns (uint256) {
    //     return dividendTracker.balanceOf(account);
    // }

    // function totalRewardsEarned(address account) public view returns (uint256) {
    //     return dividendTracker.accumulativeDividendOf(account);
    // }

    // function excludeFromDividends(address account) external onlyOwner {
    //     dividendTracker.excludeFromDividends(account);
    // }

    // function getAccountDividendsInfo(
    //     address account
    // )
    //     external
    //     view
    //     returns (
    //         address,
    //         int256,
    //         int256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256
    //     )
    // {
    //     return dividendTracker.getAccount(account);
    // }

    // function getAccountDividendsInfoAtIndex(
    //     uint256 index
    // )
    //     external
    //     view
    //     returns (
    //         address,
    //         int256,
    //         int256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256
    //     )
    // {
    //     return dividendTracker.getAccountAtIndex(index);
    // }

    // function processDividendTracker(uint256 gas) external {
    //     (
    //         uint256 iterations,
    //         uint256 claims,
    //         uint256 lastProcessedIndex
    //     ) = dividendTracker.process(gas);
    //     emit ProcessedDividendTracker(
    //         iterations,
    //         claims,
    //         lastProcessedIndex,
    //         false,
    //         gas,
    //         tx.origin
    //     );
    // }

    // function claim() external {
    //     dividendTracker.processAccount(payable(msg.sender), false);
    // }

    // function claimAddress(address claimee) external onlyOwner {
    //     dividendTracker.processAccount(payable(claimee), false);
    // }

    // function getLastProcessedIndex() external view returns (uint256) {
    //     return dividendTracker.getLastProcessedIndex();
    // }

    // function setLastProcessedIndex(uint256 index) external onlyOwner {
    //     dividendTracker.setLastProcessedIndex(index);
    // }

    // function getNumberOfDividendTokenHolders() external view returns (uint256) {
    //     return dividendTracker.getNumberOfTokenHolders();
    // }

    describe('Dividends', function () {
        it('Should set the swap tokens at amount', async function () {
            const totalSupply = await getPartyTokenV3.totalSupply();
            const newAmount = totalSupply / BigInt(100_000); // Asegúrate de que este número cumple con el requisito de ser mayor que 0.001% del suministro total
            const adjustedAmount = newAmount + BigInt(1); // Ajustar ligeramente para cumplir con el requisito
            await getPartyTokenV3.setSwapTokensAtAmount(adjustedAmount);
            expect(await getPartyTokenV3.swapTokensAtAmount()).to.equal(adjustedAmount);
        });

        it('Should set the swap enabled', async function () {
            const enabled = true;
            const currentEnabled = await getPartyTokenV3.swapEnabled();
            if (currentEnabled !== enabled) {
                await getPartyTokenV3.setSwapEnabled(enabled);
            }
            expect(await getPartyTokenV3.swapEnabled()).to.equal(enabled);
        });

        it('Should update the gas for processing', async function () {
            const newValue = 300_000;
            const currentValue = await getPartyTokenV3.gasForProcessing();
            if (parseInt(currentValue) !== newValue) {
                await getPartyTokenV3.updateGasForProcessing(newValue);
            }
            expect(await getPartyTokenV3.gasForProcessing()).to.equal(newValue);
        });

        // it('Should update the minimum balance for dividends', async function () {
        //     const newMinimumBalance = 100;
        //     await getPartyTokenV3.updateMinimumBalanceForDividends(newMinimumBalance);
        //     const dividendTracker = await getPartyTokenV3.dividendTracker();
        //     expect(await getPartyTokenV3.dividendTracker.minimumTokenBalanceForDividends()).to.equal(newMinimumBalance);
        // });

        // it('Should update the claim wait', async function () {
        //     const newClaimWait = 3_601;
        //     await getPartyTokenV3.updateClaimWait(newClaimWait);
        //     expect(await getPartyTokenV3.dividendTracker.claimWait()).to.equal(newClaimWait);
        // });

        it('Should get the claim wait', async function () {
            expect(await getPartyTokenV3.getClaimWait()).to.equal(3_600);
        });

        it('Should get the total dividends distributed', async function () {
            expect(await getPartyTokenV3.getTotalDividendsDistributed()).to.equal(0);
        });

        it('Should get the withdrawable dividend of an account', async function () {
            expect(await getPartyTokenV3.withdrawableDividendOf(owner.address)).to.equal(0);
        });

        it('Should get the dividend token balance of an account', async function () {
            expect(await getPartyTokenV3.dividendTokenBalanceOf(owner.address)).to.equal(0);
        });

        it('Should get the total rewards earned of an account', async function () {
            expect(await getPartyTokenV3.totalRewardsEarned(owner.address)).to.equal(0);
        });

        // it('Should exclude an account from dividends', async function () {
        //     await getPartyTokenV3.excludeFromDividends(owner.address);
        //     expect(await getPartyTokenV3.dividendTracker.excludedFromDividends(owner.address)).to.equal(true);
        // });

        it('Should get the account dividends info', async function () {
            const account = await getPartyTokenV3.getAccountDividendsInfo(owner.address);
            console.log(account);
            expect(account[0]).to.equal(owner.address);
            expect(account[1]).to.equal(0);
            // expect(account[2]).to.equal(0);
            // expect(account[3]).to.equal(0);
            // expect(account[4]).to.equal(0);
            // expect(account[5]).to.equal(0);
            // expect(account[6]).to.equal(0);
            // expect(account[7]).to.equal(0);
        });

        // it('Should process the dividend tracker', async function () {
        //     await getPartyTokenV3.processDividendTracker(100);
        //     expect(await getPartyTokenV3.dividendTracker.getLastProcessedIndex()).to.equal(0);
        // });

        // it('Should claim dividends', async function () {
        //     await getPartyTokenV3.claim();
        //     expect(await getPartyTokenV3.dividendTracker.getLastProcessedIndex()).to.equal(0);
        // });

        // it('Should claim address dividends', async function () {
        //     await getPartyTokenV3.claimAddress(owner.address);
        //     expect(await getPartyTokenV3.dividendTracker.getLastProcessedIndex()).to.equal(0);
        // });

        it('Should get the last processed index', async function () {
            expect(await getPartyTokenV3.getLastProcessedIndex()).to.equal(0);
        });

        // it('Should set the last processed index', async function () {
        //     await getPartyTokenV3.setLastProcessedIndex(1);
        //     expect(await getPartyTokenV3.dividendTracker.getLastProcessedIndex()).to.equal(1);
        // });

        it('Should get the number of dividend token holders', async function () {
            expect(await getPartyTokenV3.getNumberOfDividendTokenHolders()).to.equal(0);
        });

        it('Should fail if not owner tries to set the swap tokens at amount', async function () {
            await expect(
                getPartyTokenV3.connect(addr1).setSwapTokensAtAmount(100)
            ).to.be.revertedWith('Ownable: caller is not the owner');
        });

        it('Should fail if not owner tries to set the swap enabled', async function () {
            await expect(
                getPartyTokenV3.connect(addr1).setSwapEnabled(true)
            ).to.be.revertedWith('Ownable: caller is not the owner');
        });

        it('Should fail if not owner tries to update the gas for processing', async function () {
            await expect(
                getPartyTokenV3.connect(addr1).updateGasForProcessing(300_000)
            ).to.be.revertedWith('Ownable: caller is not the owner');
        });

        it('Should fail if not owner tries to update the minimum balance for dividends', async function () {
            await expect(
                getPartyTokenV3.connect(addr1).updateMinimumBalanceForDividends(100)
            ).to.be.revertedWith('Ownable: caller is not the owner');
        });

        it('Should fail if not owner tries to update the claim wait', async function () {
            await expect(
                getPartyTokenV3.connect(addr1).updateClaimWait(3_600)
            ).to.be.revertedWith('Ownable: caller is not the owner');
        });

        it('Should fail if not owner tries to exclude an account from dividends', async function () {
            await expect(
                getPartyTokenV3.connect(addr1).excludeFromDividends(owner.address)
            ).to.be.revertedWith('Ownable: caller is not the owner');
        });

        it('Should fail if not owner tries to process the dividend tracker', async function () {

            // function processDividendTracker(uint256 gas) external {
            //     (
            //         uint256 iterations,
            //         uint256 claims,
            //         uint256 lastProcessedIndex
            //     ) = dividendTracker.process(gas);
            //     emit ProcessedDividendTracker(
            //         iterations,
            //         claims,
            //         lastProcessedIndex,
            //         false,
            //         gas,
            //         tx.origin
            //     );
            // } 

            await expect(
                getPartyTokenV3.connect(addr1).processDividendTracker(100)
            ).to.be.revertedWith('Ownable: caller is not the owner');
        });

        it('Should fail if not owner tries to claim dividends', async function () {
            await expect(
                getPartyTokenV3.connect(addr1).claim()
            ).to.be.revertedWith('Ownable: caller is not the owner');
        });

        it('Should fail if not owner tries to claim address dividends', async function () {
            await expect(
                getPartyTokenV3.connect(addr1).claimAddress(owner.address)
            ).to.be.revertedWith('Ownable: caller is not the owner');
        });

        it('Should fail if not owner tries to set the last processed index', async function () {
            await expect(
                getPartyTokenV3.connect(addr1).setLastProcessedIndex(1)
            ).to.be.revertedWith('Ownable: caller is not the owner');
        });
    });
});