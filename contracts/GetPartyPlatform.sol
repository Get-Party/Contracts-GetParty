// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GetPartyPlatform is ReentrancyGuard {
    IERC20 public token;
    uint256 public ticketPrice;
    mapping(uint256 => address) public ticketOwners;
    uint256 public nextTicketId;

    constructor(IERC20 _token, uint256 _ticketPrice) {
        token = _token;
        ticketPrice = _ticketPrice;
        nextTicketId = 0;
    }

    function buyTicket() public nonReentrant {
        require(
            token.transferFrom(msg.sender, address(this), ticketPrice),
            "Token transfer failed"
        );
        ticketOwners[nextTicketId] = msg.sender;
        nextTicketId++;
    }

    function sellTicket(uint256 ticketId) public nonReentrant {
        require(
            ticketOwners[ticketId] == msg.sender,
            "You don't own this ticket"
        );
        require(
            token.transfer(msg.sender, ticketPrice),
            "Token transfer failed"
        );
        ticketOwners[ticketId] = address(0);
    }

    function setTicketPrice(uint256 _ticketPrice) public {
        // Aquí deberías asegurarte de que solo el dueño o una entidad autorizada pueda cambiar el precio
        ticketPrice = _ticketPrice;
    }
}
