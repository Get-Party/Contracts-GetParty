// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GetPartyToken is ERC20, Ownable, ReentrancyGuard {
    uint256 public buyFeePercent;

    constructor(
        uint256 initialSupply,
        uint256 _buyFeePercent
    ) ERC20("GetPartyToken", "GPT") {
        _mint(msg.sender, initialSupply);
        buyFeePercent = _buyFeePercent;
    }

    function setBuyFeePercent(uint256 newBuyFeePercent) public onlyOwner {
        buyFeePercent = newBuyFeePercent;
    }

    function buyTokens() public payable nonReentrant {
        require(msg.value > 0, "Need to send ETH to buy tokens");
        uint256 fee = (msg.value * buyFeePercent) / 100;
        uint256 amountToBuy = msg.value - fee;
        payable(owner()).transfer(fee);
        _mint(msg.sender, amountToBuy);
    }
}
