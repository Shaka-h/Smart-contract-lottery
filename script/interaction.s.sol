//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract CreateSubscription is Script {
    function createSubscriptionWithConfig() public returns (uint256 _subId) {
        HelperConfig helperConfig = new HelperConfig();
        address vrf_coordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subId = createSubscription(vrf_coordinator);
        return subId;
    }

    function run() public {
        createSubscriptionWithConfig();
    }

    function createSubscription(address vrf_coordinator) public returns (uint256 _subId) {
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrf_coordinator).createSubscription();
        console2.log("Subscription ID: ", subId);
        vm.stopBroadcast();

        return subId;
    }
}

contract FundSubscription is Script {
    uint256 constant FUND_AMOUNT = 3 ether;

    // function fundSubscriptionWithConfig() public {
    //     HelperConfig helperConfig = new HelperConfig();
    //     address vrf_coordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
    //     fundSubscription(vrf_coordinator, _subId);
    // }

    // function run() public {
    //     fundSubscriptionWithConfig(uint256 _subId, uint96 _amount);
    // }

    function fundSubscription(address vrf_coordinator, uint256 _subId) public {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrf_coordinator).fundSubscription(_subId, FUND_AMOUNT);
        vm.stopBroadcast();
    }
}
