/*────────────────────────────┐
  Total supply: 100.000.000
  Name: GET PARTY
  Symbol: GPT
  Decimals: 18

  t.me/getpartyapp
  getparty.app
  @getparty.app
  twitter.com/getparty_

  Project Developed by Compulsive Coders - https://compulsivecoders.tech/
──────────────────────────────┘

 SPDX-License-Identifier: MIT */

pragma solidity 0.8.24;

// Uniswap imports
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// Locally developed imports
import "./DividendTracker.sol";

contract GetPartyTokenV3 is ERC20, Ownable {
    uint256 private liquidityFeeOnBuy;
    uint256 public treasuryFeeOnBuy;
    uint256 public rewardsFeeOnBuy;

    uint256 private totalBuyFee;

    uint256 private liquidityFeeOnSell;
    uint256 public treasuryFeeOnSell;
    uint256 public rewardsFeeOnSell;

    uint256 private totalSellFee;

    address public treasuryWallet;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    DividendTracker public dividendTracker;
    address public immutable rewardToken;
    uint256 public gasForProcessing = 300_000;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event TreasuryWalletChanged(address treasuryWallet);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SellFeesUpdated(uint256 totalSellFee);
    event BuyFeesUpdated(uint256 totalBuyFee);
    event TransferFeesUpdated(uint256 fee1, uint256 fee2);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SendMarketing(uint256 ethSend);
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );
    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );
    event SendDividends(uint256 amount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() ERC20(unicode"GETPARTY", unicode"GPT") {
        rewardToken = address(this);

        liquidityFeeOnBuy = 0;
        treasuryFeeOnBuy = 2;
        rewardsFeeOnBuy = 1;

        totalBuyFee = liquidityFeeOnBuy + treasuryFeeOnBuy + rewardsFeeOnBuy;

        liquidityFeeOnSell = 0;
        treasuryFeeOnSell = 2;
        rewardsFeeOnSell = 1;

        totalSellFee =
            liquidityFeeOnSell +
            treasuryFeeOnSell +
            rewardsFeeOnSell;

        treasuryWallet = 0xE43E787739D85af175d55e82B99F995401e02756; // Marketing, Development, Community Gifts.

        dividendTracker = new DividendTracker(5_000_000, rewardToken);

        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
        //     0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        // ); // ETH Mainnet
        // Sepolia Testnet 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008
        );

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(DEAD);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        dividendTracker.excludeFromDividends(
            address(0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE)
        );

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[
            address(0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE)
        ] = true;

        _mint(owner(), 100_000_000 * (10 ** 18));
        swapTokensAtAmount = totalSupply() / 5000;
    }

    receive() external payable {}

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim native tokens");
        if (token == address(0x0)) {
            sendETH(payable(msg.sender), address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendETH(
        address payable recipient,
        uint256 amount
    ) internal returns (bool) {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        return success;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already set to that state"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function updateBuyFees(
        uint256 _liquidityFeeOnBuy,
        uint256 _treasuryFeeOnBuy,
        uint256 _rewardsFeeOnBuy
    ) external onlyOwner {
        liquidityFeeOnBuy = _liquidityFeeOnBuy;
        treasuryFeeOnBuy = _treasuryFeeOnBuy;
        rewardsFeeOnBuy = _rewardsFeeOnBuy;

        totalBuyFee = _liquidityFeeOnBuy + _treasuryFeeOnBuy + _rewardsFeeOnBuy;

        require(totalBuyFee <= 10, "Buy fee cannot be more than 10%");

        emit BuyFeesUpdated(totalBuyFee);
    }

    function updateSellFees(
        uint256 _liquidityFeeOnSell,
        uint256 _treasuryFeeOnSell,
        uint256 _rewardsFeeOnSell
    ) external onlyOwner {
        liquidityFeeOnSell = _liquidityFeeOnSell;
        treasuryFeeOnSell = _treasuryFeeOnSell;
        rewardsFeeOnSell = _rewardsFeeOnSell;

        totalSellFee =
            _liquidityFeeOnSell +
            _treasuryFeeOnSell +
            _rewardsFeeOnSell;

        require(totalSellFee <= 10, "Sell fee cannot be more than 10%");

        emit SellFeesUpdated(totalSellFee);
    }

    function changeTreasuryWallet(address _treasuryWallet) external onlyOwner {
        require(
            _treasuryWallet != treasuryWallet,
            "Marketing wallet is already that address"
        );
        require(
            !isContract(_treasuryWallet),
            "Marketing wallet cannot be a contract"
        );
        require(
            _treasuryWallet != address(0),
            "Marketing wallet cannot be the zero address"
        );
        treasuryWallet = _treasuryWallet;
        emit TreasuryWalletChanged(treasuryWallet);
    }

    bool public tradingEnabled;
    bool public swapEnabled;

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled.");
        tradingEnabled = true;
        swapEnabled = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            tradingEnabled ||
                _isExcludedFromFees[from] ||
                _isExcludedFromFees[to],
            "Trading not yet enabled!"
        );

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            automatedMarketMakerPairs[to] &&
            swapEnabled &&
            totalBuyFee + totalSellFee > 0
        ) {
            swapping = true;

            uint256 liquidityTokens;

            if (liquidityFeeOnBuy + liquidityFeeOnSell > 0) {
                liquidityTokens =
                    (contractTokenBalance *
                        (liquidityFeeOnBuy + liquidityFeeOnSell)) /
                    (totalBuyFee + totalSellFee);
                swapAndLiquify(liquidityTokens);
            }

            contractTokenBalance -= liquidityTokens;

            uint256 ethShare = (treasuryFeeOnBuy + treasuryFeeOnSell) +
                (rewardsFeeOnBuy + rewardsFeeOnSell);

            if (contractTokenBalance > 0 && ethShare > 0) {
                uint256 initialBalance = address(this).balance;

                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = uniswapV2Router.WETH();

                uniswapV2Router
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(
                        contractTokenBalance,
                        0,
                        path,
                        address(this),
                        block.timestamp
                    );

                uint256 newBalance = address(this).balance - initialBalance;

                if ((treasuryFeeOnBuy + treasuryFeeOnSell) > 0) {
                    uint256 treasuryETH = (newBalance *
                        (treasuryFeeOnBuy + treasuryFeeOnSell)) / ethShare;
                    sendETH(payable(treasuryWallet), treasuryETH);
                    emit SendMarketing(treasuryETH);
                }

                if ((rewardsFeeOnBuy + rewardsFeeOnSell) > 0) {
                    uint256 rewardETH = (newBalance *
                        (rewardsFeeOnBuy + rewardsFeeOnSell)) / ethShare;
                    swapAndSendDividends(rewardETH);
                }
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        // w2w & not excluded from fees
        if (from != uniswapV2Pair && to != uniswapV2Pair && takeFee) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 _totalFees;
            if (from == uniswapV2Pair) {
                _totalFees = totalBuyFee;
            } else {
                _totalFees = totalSellFee;
            }
            uint256 fees = (amount * _totalFees) / 100;

            amount = amount - fees;

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try
            dividendTracker.setBalance(payable(from), balanceOf(from))
        {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch {}
        }
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            half,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        uint256 newBalance = address(this).balance - initialBalance;

        uniswapV2Router.addLiquidityETH{value: newBalance}(
            address(this),
            otherHalf,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            DEAD,
            block.timestamp
        );

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapAndSendDividends(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = rewardToken;

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, address(this), block.timestamp);

        uint256 balanceRewardToken = IERC20(rewardToken).balanceOf(
            address(this)
        );
        bool success = IERC20(rewardToken).transfer(
            address(dividendTracker),
            balanceRewardToken
        );

        if (success) {
            dividendTracker.distributeDividends(balanceRewardToken);
            emit SendDividends(balanceRewardToken);
        }
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount > totalSupply() / 100_000,
            "SwapTokensAtAmount must be greater than 0.001% of total supply"
        );
        swapTokensAtAmount = newAmount;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        require(swapEnabled != _enabled, "swapEnabled already at this state.");
        swapEnabled = _enabled;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(
            newValue >= 200_000 && newValue <= 500_000,
            "gasForProcessing must be between 200,000 and 500,000"
        );
        require(
            newValue != gasForProcessing,
            "Cannot update gasForProcessing to same value"
        );
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateMinimumBalanceForDividends(
        uint256 newMinimumBalance
    ) external onlyOwner {
        dividendTracker.updateMinimumTokenBalanceForDividends(
            newMinimumBalance
        );
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(
            newClaimWait >= 3_600 && newClaimWait <= 86_400,
            "claimWait must be updated to between 1 and 24 hours"
        );
        dividendTracker.updateClaimWait(newClaimWait);
    }

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function totalRewardsEarned(address account) public view returns (uint256) {
        return dividendTracker.accumulativeDividendOf(account);
    }

    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    function getAccountDividendsInfo(
        address account
    )
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(
        uint256 index
    )
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function claimAddress(address claimee) external onlyOwner {
        dividendTracker.processAccount(payable(claimee), false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function setLastProcessedIndex(uint256 index) external onlyOwner {
        dividendTracker.setLastProcessedIndex(index);
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
}
