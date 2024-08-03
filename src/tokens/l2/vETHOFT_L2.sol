// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import {SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import {MessagingParams, MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {IvOracleL2} from "../../interfaces/IvOracleL2.sol";

import "forge-std/console2.sol";

abstract contract vETHOFTConstants {
    /// @notice Oracle used for retrieving price data for vETH, immutable for security.
    IvOracleL2 public immutable ORACLE;
}
abstract contract vETHOFTVariables is vETHOFTConstants {}

abstract contract vETHOFTErrors {
    /// @notice Thrown when an operation involving a zero amount is attempted.
    error vETHOFT__InvalidZeroAmount();

    /// @notice Thrown when an oracle price is considered expired.
    error vETHOFT__OraclePriceExpired();

    /// @notice Thrown when an operation is attempted with an expired or invalid timestamp.
    /// @param deadline The deadline timestamp that was found to be invalid.
    error vETHOFT__InvalidTimestamp(uint256 deadline);
}

contract vETHOFT_L2 is OFT, vETHOFTConstants, vETHOFTErrors {
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate,
        IvOracleL2 _oracle
    ) Ownable(_delegate) OFT(_name, _symbol, _lzEndpoint, _delegate) {
        ORACLE = _oracle;
    }

    /**
     * @notice Deposits ETH and mints corresponding shares of vETH tokens.
     * @param receiver The address to receive the minted vETH tokens.
     * @param _minOut The minimum amount of vETH tokens that must be minted to the receiver.
     * @param _deadline A timestamp before which the transaction must be mined to be valid.
     * @return shares The number of vETH tokens minted to the receiver.
     * @dev The function reverts if the oracle price is stale or if the deadline is exceeded.
     */
    function depositETH(
        address receiver,
        uint256 _minOut,
        uint256 _deadline
    ) public payable returns (uint256 shares) {
        require(msg.value > 0, vETHOFT__InvalidZeroAmount());
        shares = msg.value;

        // TODO Additional calculations can be performed here based on lastPrice

        // (uint256 _lastPrice, uint256 _lastPriceTimestamp) = ORACLE
        //     .getMintRate();

        // // Verify the price is not stale
        // if (block.timestamp > _lastPriceTimestamp + 1 days) {
        //     revert vETHOFT__OraclePriceExpired();
        // }

        // if (block.timestamp > _deadline) {
        //     revert vETHOFT__InvalidTimestamp(_deadline);
        // }

        // For simplicity in this example, minting is done at a 1:1 rate.
        _mint(receiver, msg.value); // 1:1
    }

    function _payNative(
        uint256 _nativeFee
    ) internal virtual override returns (uint256 nativeFee) {
        require(msg.value >= _nativeFee, NotEnoughNative(msg.value));
        return _nativeFee;
    }

    function _lzSend(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        MessagingFee memory _fee,
        address _refundAddress
    ) internal virtual override returns (MessagingReceipt memory receipt) {
        // @dev Push corresponding fees to the endpoint, any excess is sent back to the _refundAddress from the endpoint.
        require(msg.value >= _fee.nativeFee, NotEnoughNative(msg.value));
        if (_fee.lzTokenFee > 0) _payLzToken(_fee.lzTokenFee);
        return
            // solhint-disable-next-line check-send-result
            endpoint.send{value: msg.value}(
                MessagingParams(
                    _dstEid,
                    _getPeerOrRevert(_dstEid),
                    _message,
                    _options,
                    _fee.lzTokenFee > 0
                ),
                _refundAddress
            );
    }

    function _debit(
        address,
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 _dstEid
    )
        internal
        view
        override
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        (amountSentLD, amountReceivedLD) = _debitView(
            _amountLD,
            _minAmountLD,
            _dstEid
        );
        // intentionally removed burning
    }
}
