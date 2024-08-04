// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IRestakingManager {
    function stake() external payable;
    function unstake(uint256 amount) external;
    function claimRewards() external;
}
