// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IvOracleL1} from "../../interfaces/IvOracleL1.sol";
import {vOracleCommonConstants} from "../vOracleCommon.sol";

abstract contract vOracleL1Constants is vOracleCommonConstants {
    /// @dev Represents a scaling factor used for all price values, defined as 10^18.
    uint256 constant SCALE_FACTOR = 10 ** 18;
}
abstract contract vOracleL1Variables is vOracleL1Constants {
    /// @dev A mapping that links each supported ERC20 token address to its corresponding Chainlink oracle address.
    mapping(IERC20 => AggregatorV3Interface) public tokenOracleLookup;
}

abstract contract vOracleL1Errors {
    /// @dev Thrown when a function receives a zero address where a valid address is expected.
    error vOracle__InvalidZeroAddress();

    /// @dev Thrown when the decimal count of a token does not match the expected value.
    error vOracle__InvalidTokenDecimals(uint8 expected, uint8 actual);

    /// @dev Thrown when no oracle is found for the specified token.
    error vOracle__OracleNotFound();

    /// @dev Thrown when the price from an oracle is older than the maximum allowable time window.
    error vOracle__OraclePriceExpired();

    /// @dev Thrown when the price received from an oracle does not meet validation criteria.
    error vOracle__InvalidOraclePrice();

    /// @dev Thrown when input arrays of different functionalities do not match in length.
    error vOracle__MismatchedArrayLengths();

    /// @dev Thrown when an amount provided to a function is invalid (e.g., zero or negative).
    error vOracle__InvalidAmount();
}

abstract contract vOracleL1Events {
    /// @dev Emitted when an oracle address is updated for a token.
    event LogOracleUpdated(IERC20 token, AggregatorV3Interface oracleAddress);
}

contract vOracle is
    IvOracleL1,
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    vOracleL1Events,
    vOracleL1Errors,
    vOracleL1Variables
{
    using Math for uint256;
    /// @dev Prevents implementation contract from being initialized.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}

    function updateOracleAddress(
        IERC20 _token,
        AggregatorV3Interface _oracleAddress
    ) external onlyOwner {
        require(address(_token) != address(0x0), vOracle__InvalidZeroAddress());

        // Verify that the pricing of the oracle is 18 decimals - pricing calculations will be off otherwise
        require(
            _oracleAddress.decimals() == 18,
            vOracle__InvalidTokenDecimals(18, _oracleAddress.decimals())
        );

        tokenOracleLookup[_token] = _oracleAddress;
        emit LogOracleUpdated(_token, _oracleAddress);
    }

    /// @inheritdoc IvOracleL1
    function lookupTokenValue(
        IERC20 _token,
        uint256 _balance
    ) public view returns (uint256 value) {
        AggregatorV3Interface oracle = getOracle(_token);
        int256 price = validateOraclePrice(oracle);
        return uint256(price).mulDiv(_balance, SCALE_FACTOR);
    }

    /// @inheritdoc IvOracleL1
    function lookupTokenAmountFromValue(
        IERC20 _token,
        uint256 _value
    ) external view returns (uint256 amount) {
        AggregatorV3Interface oracle = getOracle(_token);
        int256 price = validateOraclePrice(oracle);
        // Since price is times 10**18, ensure token amount is scaled appropriately.
        return _value.mulDiv(SCALE_FACTOR, uint256(price));
    }

    // Internal helper functions

    /**
     * @dev Retrieves the oracle for a given token and validates its existence.
     * @param _token The ERC20 token address whose oracle is to be retrieved.
     * @return oracle The oracle address associated with the token.
     */
    function getOracle(
        IERC20 _token
    ) internal view returns (AggregatorV3Interface oracle) {
        oracle = tokenOracleLookup[_token];
        require(address(oracle) != address(0), vOracle__OracleNotFound());
        return oracle;
    }

    /**
     * @dev Validates the price from an oracle, checking for freshness and positivity.
     * @param oracle The oracle from which to retrieve the price.
     * @return price The latest valid price from the oracle.
     */
    function validateOraclePrice(
        AggregatorV3Interface oracle
    ) internal view returns (int256) {
        (, int256 price, , uint256 timestamp, ) = oracle.latestRoundData();
        require(
            timestamp >= block.timestamp - MAX_TIME_WINDOW,
            vOracle__OraclePriceExpired()
        );
        require(price > 0, vOracle__InvalidOraclePrice());
        return price;
    }

    /// @notice Calculates the amount of new tokens to mint based on the value added to the protocol.
    /// @dev Uses proportional logic based on the existing supply and current protocol value to determine mint amount.
    /// @param protocolValue Total current value locked in the protocol.
    /// @param valueAdded Value being added to the protocol.
    /// @param totalSupply Current total supply of tokens.
    /// @return mintAmount The amount of tokens to mint.
    function calculateMintAmount(
        uint256 protocolValue,
        uint256 valueAdded,
        uint256 totalSupply
    ) external pure returns (uint256 mintAmount) {
        // for the initial mint, simply return the new value added, guarding against manipulating the initial mint
        if (protocolValue == 0 || totalSupply == 0) {
            return valueAdded;
        }

        // calculate mint amount based on the proportional increase in protocol value
        mintAmount = totalSupply.mulDiv(valueAdded, protocolValue);
        require(mintAmount != 0, vOracle__InvalidAmount());

        return mintAmount;
    }

    /// @inheritdoc IvOracleL1
    function calculateRedeemAmount(
        uint256 tokensBurned,
        uint256 totalSupply,
        uint256 protocolValue
    ) external pure returns (uint256 redeemAmount) {
        // calculate the redeemable value as a proportion of the total protocol value
        redeemAmount = protocolValue.mulDiv(tokensBurned, totalSupply);

        require(redeemAmount != 0, vOracle__InvalidAmount());

        return redeemAmount;
    }
}
