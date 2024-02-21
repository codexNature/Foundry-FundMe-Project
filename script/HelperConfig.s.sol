//1. Deploy mocks when we are on a local anvil chain
//2. Keep track of contract address across different chains
// Sepolia ETH/USD has a didderent address
// Mainnet ETH/USD has a didderent address

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";


contract HelperConfig is Script { //If we are on local anvil, we deploy Mock, Other grab the existing address from the live network.
      NetworkConfig public activeNetworkConfig;

      uint8 public constant DECIMALS=8;//This line is from MockV3Aggregator in the consytructor line , demicals and initial_price
      int256 public constant   INITIAL_PRICE = 2000e8; //This line is from MockV3Aggregator in the consytructor line , demicals and initial_price

    struct NetworkConfig {
      address priceFeed; //ETH/USD price feed address. Made it a type
    }

   constructor() {
    if (block.chainid == 11155111) {
        activeNetworkConfig = getSepoliaEthConfig();//This is how we set the active network config if we are on sepolia.
    } else if (block.chainid == 1) {
      activeNetworkConfig = getEthConfig();
    } else if (block.chainid == 137 ){
      activeNetworkConfig = getPolygonConfig();
    } else {
      activeNetworkConfig = getOrCreateAnvilEthConfig();//This is how we set the active network config if we are on anvil.
    }
   } 

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory) { // This is going to rertun configuration for everything we need in sepolia or anychain.
          //price feed address
          NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
          });
          return sepoliaConfig;
    } //grab the existing address from the live network. If we are on sepolia we return this.

    function getEthConfig() public pure returns(NetworkConfig memory) { // This is going to rertun configuration for everything we need in sepolia or anychain.
          //price feed address
          NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
          });
          return ethConfig;
    }//To deploy to anychain simply just write the function for the chain and get chain id from chain list and pricefeed address from chainlink docs.

    function getPolygonConfig() public pure returns(NetworkConfig memory) {
        NetworkConfig memory polygonConfig = NetworkConfig({
          priceFeed: 0xF9680D99D6C9589e2a93a78A04A279e509205945
        });
        return polygonConfig;
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }


          //price feed address
          //dEPLOY THE MOCKS
          //rETURN THE MOCK ADDRESS

          vm.startBroadcast();
          MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS, 
            INITIAL_PRICE
            );
          vm.stopBroadcast();

          NetworkConfig memory anvilConfig = NetworkConfig({
                priceFeed: address(mockPriceFeed)
          });
          return anvilConfig;
    }
   //If we are on Anvil we return this.
}
