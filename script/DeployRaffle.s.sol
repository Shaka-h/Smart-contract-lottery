// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    uint256 entryFees;
    uint256 timeInterval;
    address _vrfV2PlusWrapper;
    uint32 callbackGasLimit;

    function run() public {}

    function deployRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getNetworkConfig();

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            networkConfig.entryFees,
            networkConfig.timeInterval,
            networkConfig._vrfV2PlusWrapper,
            networkConfig.callbackGasLimit
        );
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
