// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

abstract contract vOracleCommonConstants {
    /// @dev Specifies the maximum allowable time interval, in seconds, for a price feed to be considered current. Beyond this duration, feeds are considered stale.
    uint256 constant MAX_TIME_WINDOW = 86400; // 24 hours
}
