// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GPTStaking is ReentrancyGuard {
    IERC20 public gptToken;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 duration;
    }

    uint256 public constant ONE_WEEK = 7 days;
    uint256 public constant TWO_WEEKS = 14 days;
    uint256 public constant ONE_MONTH = 30 days;
    uint256 public constant PENALTY_RATE = 50; // 50% penalty for emergency withdrawal

    mapping(address => Stake) public stakes;
    mapping(uint256 => uint256) public rewardRates; // Duration in seconds => Reward Rate

    constructor(address _gptTokenAddress) {
        gptToken = IERC20(_gptTokenAddress);
        rewardRates[ONE_WEEK] = 5; // 5% reward rate for 1 week staking
        rewardRates[TWO_WEEKS] = 10; // 10% for 2 weeks
        rewardRates[ONE_MONTH] = 20; // 20% for 1 month
    }

    function fundContract(uint256 amount) public {
        gptToken.transferFrom(msg.sender, address(this), amount);
    }

    function stake(uint256 amount, uint256 duration) external nonReentrant {
        require(
            duration == ONE_WEEK ||
                duration == TWO_WEEKS ||
                duration == ONE_MONTH,
            "Invalid staking duration"
        );
        require(stakes[msg.sender].amount == 0, "Existing stake detected");

        uint256 potentialReward = (amount * rewardRates[duration]) / 100;
        uint256 totalPayout = amount + potentialReward;

        require(
            gptToken.balanceOf(address(this)) >= totalPayout,
            "Insufficient contract funds for reward"
        );

        gptToken.transferFrom(msg.sender, address(this), amount);

        stakes[msg.sender] = Stake({
            amount: amount,
            startTime: block.timestamp,
            duration: duration
        });
    }

    function unstake() external nonReentrant {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No active stake");
        require(
            block.timestamp >= userStake.startTime + userStake.duration,
            "Stake period not finished"
        );

        uint256 reward = (userStake.amount * rewardRates[userStake.duration]) /
            100;
        uint256 totalPayout = userStake.amount + reward;

        require(
            gptToken.balanceOf(address(this)) >= totalPayout,
            "Insufficient funds in contract"
        );

        gptToken.transfer(msg.sender, totalPayout);

        delete stakes[msg.sender];
    }

    function emergencyWithdraw() external nonReentrant {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No active stake");

        uint256 penaltyAmount = (userStake.amount * PENALTY_RATE) / 100;
        uint256 returnedAmount = userStake.amount - penaltyAmount;

        require(
            gptToken.balanceOf(address(this)) >= returnedAmount,
            "Insufficient funds in contract"
        );

        gptToken.transfer(msg.sender, returnedAmount);

        delete stakes[msg.sender];
    }
}
