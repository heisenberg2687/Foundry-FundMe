// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address priceFeed;
    }

    NetworkConfig public s_activeNetworkConfig;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8; // 2000 USD in 8 decimals

    constructor() {
        if (block.chainid == 11155111) {
            s_activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
           s_activeNetworkConfig = getMainnetEthConfig();
        } else {
            s_activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaEthConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaEthConfig;
    }
    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetEthConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return mainnetEthConfig;
    }
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if(s_activeNetworkConfig.priceFeed != address(0)){
             return s_activeNetworkConfig;
         }
        vm.startBroadcast();
         MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
         // Deploy a mock aggregator for testing purposes
        vm.stopBroadcast();
         NetworkConfig memory anvilEthConfig = NetworkConfig({
            priceFeed: address(mockV3Aggregator)
         });
         return anvilEthConfig;
    }
}