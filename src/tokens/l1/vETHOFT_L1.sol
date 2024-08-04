// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import {SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import {IRestakingManager} from "../../interfaces/IRestakingManager.sol";

import "forge-std/console2.sol";

abstract contract vETHOFTConstants {
    /// @dev TODO netspec
    IRestakingManager immutable RESTAKING_MANAGER;
}
contract vETHOFT_L1 is OFT, vETHOFTConstants {
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate,
        IRestakingManager _restakingManager
    ) Ownable(_delegate) OFT(_name, _symbol, _lzEndpoint, _delegate) {
        RESTAKING_MANAGER = _restakingManager;
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
        // removed burning
    }

    function _credit(
        address,
        uint256 _amountLD,
        uint32 /*_srcEid*/
    ) internal override returns (uint256 amountReceivedLD) {
        RESTAKING_MANAGER.stake{value: _amountLD}();
        return _amountLD;
    }
}
