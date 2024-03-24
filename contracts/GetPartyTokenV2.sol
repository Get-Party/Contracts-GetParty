// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract GetPartyTokenV2 is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public buyFeePercent;
    uint256 public sellFeePercent;
    address public marketingWallet;
    address public liquidityWallet;

    IUniswapV2Router02 public uniswapRouter;
    address public uniswapPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public numTokensSellToAddToLiquidity;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
        uint256 initialSupply,
        uint256 _buyFeePercent,
        uint256 _sellFeePercent,
        address _marketingWallet,
        address _liquidityWallet,
        address routerAddress
    ) ERC20("GetPartyToken", "GPT") {
        require(
            _marketingWallet != address(0),
            "GetPartyToken: Marketing wallet is the zero address"
        );
        require(
            _liquidityWallet != address(0),
            "GetPartyToken: Liquidity wallet is the zero address"
        );

        buyFeePercent = _buyFeePercent;
        sellFeePercent = _sellFeePercent;
        marketingWallet = _marketingWallet;
        liquidityWallet = _liquidityWallet;

        numTokensSellToAddToLiquidity = initialSupply / 1000; // Example threshold

        IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(routerAddress);
        uniswapPair = IUniswapV2Factory(_uniswapRouter.factory()).createPair(
            address(this),
            _uniswapRouter.WETH()
        );

        uniswapRouter = _uniswapRouter;

        _mint(owner(), initialSupply);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapPair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }

        uint256 feePercent = from == uniswapPair
            ? buyFeePercent
            : sellFeePercent;
        uint256 fee = (amount * feePercent) / 100;
        uint256 transferAmount = amount - fee;

        super._transfer(from, address(this), fee);
        super._transfer(from, to, transferAmount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // Split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // Capture the contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        // Swap tokens for ETH
        swapTokensForEth(half);

        // How much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // Add liquidity to Uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // Make the swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapRouter), tokenAmount);

        // Add the liquidity
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    // To receive ETH from uniswapRouter when swapping
    receive() external payable {}

    // Allow the owner to withdraw ETH
    function withdrawETH(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient ETH balance");
        payable(owner()).transfer(amount);
    }

    // Allow the owner to withdraw tokens
    function withdrawTokens(address token, uint256 amount) public onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }
}
