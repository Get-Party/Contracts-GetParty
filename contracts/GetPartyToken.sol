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

pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

contract GetPartyToken is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;

    address payable private _taxWallet;
    address payable private _marketingWallet;
    address payable private _stakingWallet;
    address payable private _airdropWallet;

    uint256 private _initialBuyTax = 7;
    uint256 private _initialSellTax = 7;
    uint256 private _finalTax = 4;
    uint256 private _reduceBuyTaxAt = 50;
    uint256 private _reduceSellTaxAt = 50;
    uint256 private _preventSwapBefore = 30;
    uint256 private _buyCount = 0;

    uint8 private constant _decimals = 8;
    uint256 private constant _supply = 100000000 * 10 ** _decimals; // $GPT - 100 million
    string private constant _name = unicode"Get Party Token";
    string private constant _symbol = unicode"GPT";
    uint256 public _maxTxAmount = 2000000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 2000000 * 10 ** _decimals;
    uint256 public _taxSwapThreshold = 50000 * 10 ** _decimals;
    uint256 public _maxTaxSwap = 150000 * 10 ** _decimals;

    IUniswapV2Router02 private uniswapV2Router;

    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private go = false;

    event ExcludeFromFeeUpdated(address indexed account);
    event ChangeTaxWallet(address indexed newTaxWallet);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address swapRouterAddr,
        address payable taxWallet,
        address payable marketingWallet,
        address payable stakingWallet,
        address payable airdropWallet
    ) {
        address _pinkSaleAddress = 0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE; // BSC PinkSale
        uniswapV2Router = IUniswapV2Router02(swapRouterAddr); // PancakeSwap Router

        _taxWallet = taxWallet; // 0% - receive taxes
        _marketingWallet = marketingWallet; // 10%
        _stakingWallet = stakingWallet; // 10%
        _airdropWallet = airdropWallet; // 5%

        _balances[_marketingWallet] = ((_supply * 10) / 100);
        _balances[_stakingWallet] = ((_supply * 10) / 100);
        _balances[_airdropWallet] = ((_supply * 5) / 100);
        _balances[owner()] = ((_supply * 75) / 100);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromFee[_taxWallet] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        _isExcludedFromFee[_stakingWallet] = true;
        _isExcludedFromFee[_airdropWallet] = true;
        _isExcludedFromFee[_pinkSaleAddress] = true;

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _supply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    receive() external payable {}

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        uint256 currentAllowance = allowance(sender, spender);
        require(currentAllowance >= amount, "ERC20: insufficient allowance");

        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(
            owner != address(0) && spender != address(0),
            "ERC20: approve to/from the zero address"
        );
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(
            from != address(0) && to != address(0),
            "ERC20: transfer from/to the zero address"
        );
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            balanceOf(from) >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        uint256 taxAmount = 0;

        if (from != owner() && to != owner()) {
            require(!bots[from]);

            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");

                taxAmount =
                    (amount *
                        (
                            (_buyCount > _reduceBuyTaxAt)
                                ? _finalTax
                                : _initialBuyTax
                        )) /
                    100;

                require(
                    balanceOf(to) + amount - taxAmount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
                _buyCount++;
            }

            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount =
                    (amount *
                        (
                            (_buyCount > _reduceSellTaxAt)
                                ? _finalTax
                                : _initialSellTax
                        )) /
                    100;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                tradingOpen &&
                contractTokenBalance > _taxSwapThreshold &&
                _buyCount > _preventSwapBefore
            ) {
                swapTokensForEth(
                    min(amount, min(contractTokenBalance, _maxTaxSwap))
                );
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + (amount - taxAmount);
        emit Transfer(from, to, amount - taxAmount);
        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)] + taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function addBots(address[] memory bots_) external onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            require(
                bots_[i] != uniswapV2Pair &&
                    bots_[i] != address(uniswapV2Router) &&
                    bots_[i] != address(this) &&
                    bots_[i] != _taxWallet
            );
            bots[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) external onlyOwner {
        for (uint i = 0; i < notbot.length; i++) {
            bots[notbot[i]] = false;
        }
    }

    function isBot(address a) external view returns (bool) {
        return bots[a];
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "Trading is already open");
        _approve(address(this), address(uniswapV2Router), _supply);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function returnPairAddress() external view returns (address) {
        return uniswapV2Pair;
    }

    function contractSwap(uint256 perAmount) external {
        uint256 tokenBalance = balanceOf(address(this));

        uint256 swapAmount = (tokenBalance * perAmount) / 100;
        require(swapAmount > 0, "No tokens to swap");
        swapTokensForEth(swapAmount);

        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "No ether to send");
        sendETHToFee(ethBalance);
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setMaxWalletSize(uint256 maxWalletSize) external onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    function setTaxSwapThreshold(uint256 taxSwapThreshold) external onlyOwner {
        _taxSwapThreshold = taxSwapThreshold;
    }

    function setMaxTaxSwap(uint256 maxTaxSwap) external onlyOwner {
        _maxTaxSwap = maxTaxSwap;
    }

    function setFinalTax(uint256 tax) external onlyOwner {
        _finalTax = tax;
    }

    function changeTaxWallet(address payable newTaxWallet) external onlyOwner {
        _taxWallet = newTaxWallet;
        _isExcludedFromFee[newTaxWallet] = true;
        emit ChangeTaxWallet(newTaxWallet);
    }

    function addExcludedFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFeeUpdated(account);
    }
}
