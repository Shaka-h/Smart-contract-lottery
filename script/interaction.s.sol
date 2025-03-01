//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig, contractConstants} from "./HelperConfig.s.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
// import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscriptionWithConfig() public returns (uint256 _subId) {
        HelperConfig helperConfig = new HelperConfig();
        address vrf_coordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        address account = helperConfig.getConfig().account;
        uint256 subId = createSubscription(vrf_coordinator, account);
        return subId;
    }

    function run() public {
        createSubscriptionWithConfig();
    }

    function createSubscription(address vrf_coordinator, address account) public returns (uint256 _subId) {
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrf_coordinator).createSubscription();
        vm.stopBroadcast();
        return subId;
    }
}

contract FundSubscription is Script, contractConstants {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionWithConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrf_coordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address link = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;
        fundSubscription(vrf_coordinator, subId, link, account);
    }

    function run() public {
        fundSubscriptionWithConfig();
    }

    function fundSubscription(address vrf_coordinator, uint256 _subId, address link, address account) public {
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrf_coordinator).fundSubscription(_subId, FUND_AMOUNT * 10000);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrf_coordinator).fundSubscription(_subId, FUND_AMOUNT);
            // LinkToken(link).transferAndCall(vrf_coordinator, FUND_AMOUNT, abi.encode(_subId));
            vm.stopBroadcast();
        }
    }
    // 3849125000000250000000000
    // 300000000000000000000
    // 400000000000000000000
}

contract AddConsumer is Script {
    function addConsumerWithConfig(address raffleContract) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrf_coordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        addConsumer(vrf_coordinator, raffleContract, subId);
    }

    // function run() public {
    //     fundSubscriptionWithConfig(uint256 _subId, uint96 _amount);
    // }

    function addConsumer(address vrf_coordinator, address contractToAddToVrf, uint256 _subId) public {
        // console2.log("Adding consumer contract: ", contractToAddToVrf);
        // console2.log("Using vrfCoordinator: ", vrf_coordinator);
        // console2.log("On ChainID: ", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrf_coordinator).addConsumer(_subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function run() external {
        //get most recent deployed Raffle contract address

        address mostRecentRaffleContract = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);

        addConsumerWithConfig(mostRecentRaffleContract);
    }
}
