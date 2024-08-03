// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IvOracleL2} from "../../interfaces/IvOracleL2.sol";
import {vOracleCommonConstants} from "../vOracleCommon.sol";
abstract contract vOracleL2Constants is vOracleCommonConstants {}
abstract contract vOracleL2Variables is vOracleL2Constants {
    AggregatorV3Interface public oracle;
}

abstract contract vOracleL2Errors {
    /// @notice Thrown when a zero address is passed to a function where a valid address is required.
    error vOracleL2__InvalidZeroAddress();

    /// @notice Thrown when the decimals of an oracle do not meet the required specifications.
    /// @param expected The expected number of decimals.
    /// @param actual The actual number of decimals returned by the oracle.
    error vOracleL2__InvalidDecimals(uint8 expected, uint8 actual);

    /// @notice Thrown when an oracle price is considered expired due to exceeding the maximum allowable time window.
    error vOracleL2__OraclePriceExpired();
}

abstract contract vOracleL2Events {
    /// @dev Emitted when an oracle address is updated for a token.
    event LogOracleUpdated(address newOracle, address oldOracle);
}

contract vOracleL2 is
    IvOracleL2,
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    vOracleL2Events,
    vOracleL2Errors,
    vOracleL2Variables
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

    /// @inheritdoc IvOracleL2
    function updateOracle(AggregatorV3Interface _oracle) external onlyOwner {
        require(
            address(_oracle) != address(0),
            vOracleL2__InvalidZeroAddress()
        );
        // Verify that the pricing of the oracle is less than or equal to 18 decimals - pricing calculations will be off otherwise
        require(
            _oracle.decimals() <= 18,
            vOracleL2__InvalidDecimals(18, _oracle.decimals())
        );

        emit LogOracleUpdated(address(_oracle), address(oracle));
        oracle = _oracle;
    }
    /// @inheritdoc IvOracleL2
    function getMintRate() public view returns (uint256, uint256) {
        (, int256 price, , uint256 timestamp, ) = oracle.latestRoundData();
        require(
            timestamp >= block.timestamp - MAX_TIME_WINDOW,
            vOracleL2__OraclePriceExpired()
        );
        // scale the price to have 18 decimals
        uint256 _scaledPrice = (uint256(price)) *
            10 ** (18 - oracle.decimals());
        return (_scaledPrice, timestamp);
    }
}
