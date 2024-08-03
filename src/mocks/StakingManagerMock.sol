// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IStakingManager} from "../interfaces/IStakingManager.sol";
import {IStakingProtocol} from "../interfaces/IStakingProtocol.sol";

// Forge imports
import "forge-std/console.sol";
import "forge-std/console2.sol";

contract StakingManagerMock is IStakingManager {
    IStakingProtocol public stakingProtocol;

    constructor(IStakingProtocol _stakingProtocol) {
        stakingProtocol = _stakingProtocol;
    }

    function stake() public payable {
        require(msg.value > 0, "You need to send some ether");
        stakingProtocol.deposit{value: msg.value}();
    }

    function unstake(uint256 amount) public {
        stakingProtocol.withdraw(amount);
    }

    function claimRewards() public {
        stakingProtocol.claimRewards();
    }
}
