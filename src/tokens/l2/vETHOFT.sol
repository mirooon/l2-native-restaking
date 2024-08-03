// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import {SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import {MessagingParams, MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

import "forge-std/console2.sol";

contract vETHOFT is OFT {
    uint256 public totalDepositedInPool;
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) Ownable(_delegate) OFT(_name, _symbol, _lzEndpoint, _delegate) {}

    function depositETH(
        address receiver
    ) public payable returns (uint256 shares) {
        require(msg.value > 0, "You need to send some ether");
        shares = msg.value;
        // TODO
        //         // Fetch price and timestamp of ezETH from the configured price feed
        // (uint256 _lastPrice, uint256 _lastPriceTimestamp) = getMintRate();

        // // Verify the price is not stale
        // if (block.timestamp > _lastPriceTimestamp + 1 days) {
        //     revert OraclePriceExpired();
        // }

        _mint(receiver, shares); // 1:1
        totalDepositedInPool += shares;
    }

    function _payNative(
        uint256 _nativeFee
    ) internal virtual override returns (uint256 nativeFee) {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);
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
        if (msg.value < _fee.nativeFee) revert NotEnoughNative(msg.value);
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
