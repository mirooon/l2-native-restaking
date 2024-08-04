// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IRestakingProtocol} from "../interfaces/IRestakingProtocol.sol";

contract RestakingProtocolMock is IRestakingProtocol {
    uint256 public totalStaked;
    uint256 public constant interestRate = 10;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public stakeTimestamps;
    mapping(address => uint256) public rewards;

    event Deposited(address indexed user, uint256 amount, uint256 total);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    function deposit() external payable override returns (uint256) {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        stakeTimestamps[msg.sender] = block.timestamp;
        totalStaked += msg.value;
        emit Deposited(msg.sender, msg.value, totalStaked);
        return msg.value;
    }

    function withdraw(uint256 amount) external override {
        uint256 balance = balances[msg.sender];
        require(balance >= amount, "Insufficient balance to withdraw");

        balances[msg.sender] -= amount;
        totalStaked -= amount;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() external override {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        rewards[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: reward}("");
        require(sent, "Failed to send Ether");

        emit RewardsClaimed(msg.sender, reward);
    }

    function updateRewards(address user) public {
        if (balances[user] > 0 && stakeTimestamps[user] != 0) {
            uint256 stakingDuration = block.timestamp - stakeTimestamps[user];
            uint256 stakingDays = stakingDuration / 86400;
            rewards[user] +=
                (((balances[user] * interestRate) / 100) * stakingDays) /
                365;
            stakeTimestamps[user] = block.timestamp;
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
