//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol"; //We wanna test that the FundMe contract is doing what it's written to do. The console is for console.log for debugging, works just like the conversional console.log in JS
import {FundMe} from "../../src/FundMe.sol"; //making the test file aware of the fundme it is suppose to test.
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/interactions.s.sol"; //Imported this instead of funding directly with the functions.

contract InteractionsTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; //10000000000000000
    uint256 constant STARTING_BAL = 10 ether;
    uint256 constant GAS_PRICE = 1;


    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run(); 
        vm.deal(USER, STARTING_BAL);
    } //setup always run first


    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        // vm.prank(USER);
        // vm.deal(USER, 2e18);
        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);

//         // address funder = fundMe.getFunder(0);
//         // assertEq(funder, USER);
   }
 }