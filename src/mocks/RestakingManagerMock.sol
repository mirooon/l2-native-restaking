// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IRestakingManager} from "../interfaces/IRestakingManager.sol";
import {IRestakingProtocol} from "../interfaces/IRestakingProtocol.sol";

// Forge imports
import "forge-std/console.sol";
import "forge-std/console2.sol";

contract RestakingManagerMock is IRestakingManager {
    IRestakingProtocol public restakingProtocol;

    constructor(IRestakingProtocol _restakingProtocol) {
        restakingProtocol = _restakingProtocol;
    }

    function stake() public payable {
        require(msg.value > 0, "You need to send some ether");
        restakingProtocol.deposit{value: msg.value}();
    }

    function unstake(uint256 amount) public {
        restakingProtocol.withdraw(amount);
    }

    function claimRewards() public {
        restakingProtocol.claimRewards();
    }
}
