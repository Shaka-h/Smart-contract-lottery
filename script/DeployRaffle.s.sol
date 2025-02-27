// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./interaction.s.sol";

//when writing scripts keep in mind what is and wwhat is not to be broadcasted!!!!

contract DeployRaffle is Script {
    uint256 entryFees;
    uint256 timeInterval;
    address _vrfV2PlusWrapper;
    uint32 callbackGasLimit;

    function run() public returns (HelperConfig, Raffle) {
        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();

        console2.log("Entry Fee: ", networkConfig.entryFees);
        console2.log("Time Interval: ", networkConfig.timeInterval);
        console2.log("VRF Wrapperr: ", networkConfig.vrfCoordinatorV2_5);
        console2.log("Callback Gas Limit: ", networkConfig.callbackGasLimit);
        console2.log("Callback Gas Limit: ", networkConfig.subscriptionId);
        // console2.log("Callback Gas Limit: ", networkConfig.gasLane);

        vm.startBroadcast();
        // vm.startBroadcast(networkConfig.account);
        if (networkConfig.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            FundSubscription fundSubscription = new FundSubscription();
            uint256 subId = createSubscription.createSubscription(networkConfig.vrfCoordinatorV2_5);
            fundSubscription.fundSubscription(networkConfig.vrfCoordinatorV2_5, subId);
        }

        Raffle raffle = new Raffle(
            networkConfig.subscriptionId,
            networkConfig.gasLane,
            networkConfig.timeInterval,
            networkConfig.entryFees,
            networkConfig.callbackGasLimit,
            networkConfig.vrfCoordinatorV2_5
        );

        console2.log("Entry FFFFFFe: ", raffle.getEntranceFees());
        //         console2.log("Time Interval: ", raffle.timeInterval);
        //         console2.log("VRF Wrapperr: ", raffle.vrfCoordinatorV2_5);
        //         console2.log("Callback Gas : ", raffle.callbackGasLimit);
        //         console2.log("Callback Gas : ", raffle.subscriptionId);
        // console2.log("Callback Gas Limit: ", networkConfig.gasLane);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();

        addConsumer.addConsumer(networkConfig.vrfCoordinatorV2_5, address(raffle), networkConfig.subscriptionId);

        // addConsumer.run();

        return (helperConfig, raffle);
    }
}
