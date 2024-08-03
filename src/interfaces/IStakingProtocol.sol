// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IStakingProtocol {
    function deposit() external payable returns (uint256);
    function withdraw(uint256 amount) external;
    function claimRewards() external;
}
