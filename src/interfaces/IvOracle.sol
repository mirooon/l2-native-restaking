// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

interface IvOracle {
    /**
     * @notice Updates the oracle address for a given token.
     * @param token The ERC20 token address whose oracle address is to be updated.
     * @param oracleAddress The new oracle address.
     */
    function updateOracleAddress(
        IERC20 token,
        AggregatorV3Interface oracleAddress
    ) external;

    /**
     * @notice Retrieves the value of tokens based on the current oracle price.
     * @param token The ERC20 token address for which to retrieve the value.
     * @param balance The amount of tokens to evaluate.
     * @return value The value of the tokens in terms of the price provided by the oracle.
     */
    function lookupTokenValue(
        IERC20 token,
        uint256 balance
    ) external view returns (uint256);

    /**
     * @notice Calculates the amount of tokens equivalent to a given value based on the current oracle price.
     * @param token The ERC20 token address for which to calculate the amount.
     * @param value The fiat value for which the equivalent token amount is needed.
     * @return amount The calculated amount of tokens.
     */
    function lookupTokenAmountFromValue(
        IERC20 token,
        uint256 value
    ) external view returns (uint256);

    /**
     * @notice Calculates the amount of new tokens to mint based on the value added to the protocol.
     * @param protocolValue Total current value locked in the protocol.
     * @param valueAdded Value being added to the protocol.
     * @param totalSupply Current total supply of tokens.
     * @return mintAmount The amount of tokens to mint.
     */
    function calculateMintAmount(
        uint256 protocolValue,
        uint256 valueAdded,
        uint256 totalSupply
    ) external returns (uint256);

    /**
     * @notice Calculates the redeemable value based on the amount of tokens being burned.
     * @param tokensBurned Amount of tokens the user wants to burn.
     * @param totalSupply Current total supply of tokens.
     * @param protocolValue Total current value locked in the protocol.
     * @return redeemAmount The value redeemable for the burned tokens.
     */
    function calculateRedeemAmount(
        uint256 tokensBurned,
        uint256 totalSupply,
        uint256 protocolValue
    ) external returns (uint256);
}
