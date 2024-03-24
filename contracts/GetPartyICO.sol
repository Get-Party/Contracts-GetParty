// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GetPartyToken.sol";

contract GetPartyICO {
    GetPartyToken public token;
    address public admin;
    uint256 public rate = 1000; // Tasa de tokens por ETH

    constructor(GetPartyToken _token) {
        token = _token;
        admin = msg.sender;
    }

    function setRate(uint256 _rate) public {
        require(msg.sender == admin, "Only admin can set rate");
        rate = _rate;
    }

    function buyTokens() public payable {
        require(msg.value > 0, "Need to send ETH to buy tokens");
        uint256 tokenAmount = msg.value * rate;
        token.transfer(msg.sender, tokenAmount);
    }

    function withdraw() public {
        require(msg.sender == admin, "Only admin can withdraw");
        payable(admin).transfer(address(this).balance);
    }
}
