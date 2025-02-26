// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
// import {LinkToken} from "../test/mocks/LinkToken.sol";

abstract contract contractConstants {
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint96 public immutable i_base_fee = 1e9;
    uint96 public immutable i_gas_price = 0.25 ether;
    int256 public immutable i_wei_per_unit_link = 4e15;
    address public FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
}

contract HelperConfig is Script, contractConstants {
    error Invalid_ChainId();

    struct NetworkConfig {
        uint256 entryFees;
        uint256 timeInterval;
        address vrfCoordinatorV2_5;
        uint32 callbackGasLimit;
        address account;
        uint256 subscriptionId;
        bytes32 gasLane;
        address link;
    }

    mapping(uint256 chainId => NetworkConfig networkConfig) public networkConfigs;

    NetworkConfig public localNetworkConfig;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getNetworkConfig(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinatorV2_5 != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getAnvilNetworkConfig();
        } else {
            revert Invalid_ChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        NetworkConfig memory net = getNetworkConfig(block.chainid);
        return net;
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            subscriptionId: 1,
            gasLane: 0x000000000000000000000000000000000000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            entryFees: 1 ether,
            timeInterval: 30,
            vrfCoordinatorV2_5: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            callbackGasLimit: 500000,
            account: FOUNDRY_DEFAULT_SENDER
        });
    }

    function getAnvilNetworkConfig() public returns (NetworkConfig memory) {
        //u need a mock to simulate transaction from the loacl network
        if (localNetworkConfig.vrfCoordinatorV2_5 != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vRFCoordinatorV2_5Mock =
            new VRFCoordinatorV2_5Mock(i_base_fee, i_gas_price, i_wei_per_unit_link);
        uint256 subscriptionId = vRFCoordinatorV2_5Mock.createSubscription();
        // LinkToken link = new LinkToken();

        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entryFees: 1.1 ether,
            timeInterval: 30,
            vrfCoordinatorV2_5: address(vRFCoordinatorV2_5Mock),
            callbackGasLimit: 500000,
            account: FOUNDRY_DEFAULT_SENDER,
            subscriptionId: subscriptionId,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            link: address(vRFCoordinatorV2_5Mock)
        });

        vm.deal(localNetworkConfig.vrfCoordinatorV2_5, 100 ether);
        return localNetworkConfig;
    }

    function getEntryFees() public view returns (NetworkConfig memory) {
        return localNetworkConfig;
    }
}
