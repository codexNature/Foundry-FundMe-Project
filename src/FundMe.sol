// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe_NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;//storage variables starts with s_ //private variable are more gas efficient than public.
    address[] private s_funders;//storage variables starts with s_
    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address private immutable i_owner; //i for immutable variables
    uint256 public constant MINIMUM_USD = 5e18; //uppercase for cinstant variables.
    AggregatorV3Interface private s_priceFeed; //Added to accomodate other networks. Storage variable have s_

     modifier onlyOwner {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe_NotOwner();
        _;
    }
    
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed); //This line allows to work with multiple chain, it will depend on the cahin that we are on, In remix you will see a pricefeed input beside deploy, 
    }

    function fund() public payable { 
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }
    
//Coded to support only Sepolia
    // function getVersion() public view returns (uint256){
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    //     return priceFeed.version();
    // }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }
    

    
    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length; //this way we only read it from storage one time. and everytime we loop through we only read it one more time.
        for (uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++){ //fundersLength is now a memory variable instead of a storage variable.
            address funder = s_funders[funderIndex];
             s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }


//rewriting the below function above so we are reading from storage alot less for gas efficiency.
    function withdraw() public onlyOwner {
        for (uint256 funderIndex=0; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }


    /**
 * View / Pure functions (getters)
 */
    function getAddressToAmountFunded(
      address fundingAddress
    ) external view returns(uint256){
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }//Two getter functions we can now use to check if the s_ variables are populated.

    function getOwner() external view returns (address) {
      return i_owner;
    }
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly
