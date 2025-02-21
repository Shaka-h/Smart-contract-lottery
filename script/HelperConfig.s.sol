// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract contractConstants {
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint96 public immutable i_base_fee = 1e9;
    uint96 public immutable i_gas_price = 0.25 ether;
    int256 public immutable i_wei_per_unit_link = 4e15;
}

contract HelperConfig is Script, contractConstants {
    error Invalid_ChainId();

    struct NetworkConfig {
        uint256 entryFees;
        uint256 timeInterval;
        address _vrfV2PlusWrapper;
        uint32 callbackGasLimit;
    }

    mapping(uint256 chainId => NetworkConfig networkConfig)
        public networkConfigs;

    NetworkConfig public localNetworkConfig;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getNetworkConfig() external returns (NetworkConfig memory) {
        if (networkConfigs[block.chainid]._vrfV2PlusWrapper != address(0)) {
            return networkConfigs[block.chainid];
        } else if (block.chainid == LOCAL_CHAIN_ID) {
            getAnvilNetworkConfig();
        } else {
            revert Invalid_ChainId();
        }
    }

    function getSepoliaEthConfig() public returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entryFees: 1 ether,
                timeInterval: 30,
                _vrfV2PlusWrapper: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                callbackGasLimit: 500000
            });
    }

    function getAnvilNetworkConfig() public returns (NetworkConfig memory) {
        //u need a mock to simulate transaction from the loacl network
        if (localNetworkConfig._vrfV2PlusWrapper != address(0)) {
            return networkConfigs[LOCAL_CHAIN_ID];
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vRFCoordinatorV2_5Mock = new VRFCoordinatorV2_5Mock(
                i_base_fee,
                i_gas_price,
                i_wei_per_unit_link
            );

        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entryFees: 1 ether,
            timeInterval: 30,
            _vrfV2PlusWrapper: address(vRFCoordinatorV2_5Mock),
            callbackGasLimit: 500000
        });
    }
}
