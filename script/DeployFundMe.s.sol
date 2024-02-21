//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script{
        function run() external returns (FundMe) {
          HelperConfig helperConfig = new HelperConfig(); //Anything before your broadcast is gonna be sent as a real transaction.
          address ethUsdPriceFeed = helperConfig.activeNetworkConfig();
          //WRapper in brackets because we returning a sytruct.
          vm.startBroadcast();
          FundMe fundMe = new FundMe(ethUsdPriceFeed);
          vm.stopBroadcast();
          return fundMe;
      }
}
