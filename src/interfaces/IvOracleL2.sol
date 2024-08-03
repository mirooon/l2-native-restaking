// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

interface IvOracleL2 {
    /**
     * @notice Updates the oracle address for the contract and verifies its decimal count.
     * @param oracle The new oracle to be set, must not be a zero address and must have decimals less than or equal to 18.
     */
    function updateOracle(AggregatorV3Interface oracle) external;

    /**
     * @notice Retrieves the current mint rate based on the oracle price, scaled to 18 decimals.
     * @return scaledPrice The current scaled price of vETH.
     * @return timestamp The timestamp of the latest price update.
     * @dev Reverts if the latest oracle price is outdated or if the price is less than 1 Ether.
     */
    function getMintRate()
        external
        view
        returns (uint256 scaledPrice, uint256 timestamp);
}
