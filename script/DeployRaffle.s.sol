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
        console2.log("VRF Wrapperr: ", networkConfig.vrfCoordinatorV2_5);
        console2.log("Creating subscription on chainId: ", networkConfig.account);

        if (networkConfig.subscriptionId == 0) {
            //error creating subid on sepolia network
            CreateSubscription createSubscription = new CreateSubscription();
            uint256 subId =
                createSubscription.createSubscription(networkConfig.vrfCoordinatorV2_5, networkConfig.account);
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                networkConfig.vrfCoordinatorV2_5, subId, networkConfig.link, networkConfig.account
            );
        }

        vm.startBroadcast();

        Raffle raffle = new Raffle(
            networkConfig.subscriptionId,
            networkConfig.gasLane,
            networkConfig.timeInterval,
            networkConfig.entryFees,
            networkConfig.callbackGasLimit,
            networkConfig.vrfCoordinatorV2_5
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();

        addConsumer.addConsumer(networkConfig.vrfCoordinatorV2_5, address(raffle), networkConfig.subscriptionId);

        return (helperConfig, raffle);
    }
}

// console2.log("Entry Fee: ", networkConfig.entryFees);
// console2.log("Time Interval: ", networkConfig.timeInterval);
// console2.log("VRF Wrapperr: ", networkConfig.vrfCoordinatorV2_5);
// console2.log("Callback Gas Limit: ", networkConfig.callbackGasLimit);
// console2.log("Callback Gas Limit: ", networkConfig.subscriptionId);
// console2.log("Callback Gas Limit: ", networkConfig.gasLane);
