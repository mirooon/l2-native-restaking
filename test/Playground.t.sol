// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {vETHOFT as vETHOFT_L1} from "../src/tokens/l1/vETHOFT.sol";
import {vETHOFT as vETHOFT_L2} from "../src/tokens/l2/vETHOFT.sol";

// OApp imports
import {IOAppOptionsType3, EnforcedOptionParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OAppOptionsType3.sol";
import {AddressCast} from "@layerzerolabs/lz-evm-protocol-v2/contracts/libs/AddressCast.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

// OFT imports
import {IOFT, SendParam, OFTReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import {OFTComposeMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";

// OZ imports
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Forge imports
import "forge-std/console.sol";
import "forge-std/console2.sol";

// DevTools imports
import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

import {TransparentUpgradeableProxy} from "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {IStakingProtocol} from "../src/interfaces/IStakingProtocol.sol";
import {IStakingManager} from "../src/interfaces/IStakingManager.sol";
import {StakingProtocolMock} from "../src/mocks/StakingProtocolMock.sol";
import {StakingManagerMock} from "../src/mocks/StakingManagerMock.sol";

contract PlaygroundTest is TestHelperOz5 {
    using OptionsBuilder for bytes;

    uint32 aEid = 1;
    uint32 bEid = 2;

    vETHOFT_L1 l1vETH;
    vETHOFT_L2 l2vETH;

    address public userA = address(0x1);
    uint256 public initialBalance = 100 ether;

    IStakingProtocol stakingProtocol = new StakingProtocolMock();
    IStakingManager stakingManager = new StakingManagerMock(stakingProtocol);

    function setUp() public virtual override {
        vm.deal(userA, 1000 ether);

        super.setUp();
        setUpEndpoints(2, LibraryType.UltraLightNode);

        l1vETH = vETHOFT_L1(
            payable(
                _deployOApp(
                    type(vETHOFT_L1).creationCode,
                    abi.encode(
                        "vETH",
                        "vETH",
                        address(endpoints[aEid]),
                        address(this),
                        stakingManager
                    )
                )
            )
        );

        l2vETH = vETHOFT_L2(
            payable(
                _deployOApp(
                    type(vETHOFT_L2).creationCode,
                    abi.encode(
                        "vETH",
                        "vETH",
                        address(endpoints[bEid]),
                        address(this)
                    )
                )
            )
        );

        // config and wire the ofts
        address[] memory ofts = new address[](2);
        ofts[0] = address(l1vETH);
        ofts[1] = address(l2vETH);
        this.wireOApps(ofts); // TODO only to one direction L2 -> L1?
    }

    function test_deposit_l2_oft() public {
        uint128 ethToDeposit = 0.1 ether;

        vm.prank(userA);
        assertEq(address(l2vETH).balance, 0);
        l2vETH.depositETH{value: ethToDeposit}(userA);

        // ========================== This part can be moved to depositETH function directly to remove explicit 'send' =================
        bytes memory options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(200000, ethToDeposit);
        SendParam memory sendParam = SendParam(
            aEid,
            addressToBytes32(address(0xCAFE)), // doesnt matter - can be restricted to same address
            ethToDeposit,
            ethToDeposit,
            options,
            "",
            ""
        );
        MessagingFee memory fee = l2vETH.quoteSend(sendParam, false);

        assertEq(l2vETH.balanceOf(userA), ethToDeposit);
        assertEq(address(l1vETH).balance, 0);
        assertEq(address(l2vETH).balance, ethToDeposit);

        vm.prank(userA);
        l2vETH.send{value: fee.nativeFee}(
            sendParam,
            fee,
            payable(address(this))
        );
        // ===================================================================================================
        verifyPackets(aEid, addressToBytes32(address(l1vETH)));
        verifyPackets(bEid, addressToBytes32(address(l2vETH)));

        assertEq(address(l2vETH).balance, ethToDeposit);
        assertEq(address(stakingProtocol).balance, ethToDeposit);
        assertEq(address(stakingManager).balance, 0);
        assertEq(l2vETH.balanceOf(userA), ethToDeposit);
        assertEq(address(l2vETH).balance, ethToDeposit);
    }
}
