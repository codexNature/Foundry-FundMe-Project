//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol"; //We wanna test that the FundMe contract is doing what it's written to do. The console is for console.log for debugging, works just like the conversional console.log in JS
import {FundMe} from "../../src/FundMe.sol"; //making the test file aware of the fundme it is suppose to test.
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; //10000000000000000
    uint256 constant STARTING_BAL = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); //This line is saying our fundMe variable of type FundMe is going to be a new FundMe contract
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run(); //line is added because DeployFundMe is a contract
        vm.deal(USER, STARTING_BAL);
    } //setup always run first

    function testMininmumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18); //Testing if minimum usd is 5e18
            //console.log(number); //run with forge test --vv the vv helps with visibility it can be vvvvv etc
            //console.log("Hello world");
    }

    function testOwnerIsMsgSender() public {
        console.log(fundMe.getOwner()); //Using console,log to find out whye the assertEq line test failed.
        console.log(msg.sender);
        //assertEq(fundMe.i_owner(), msg.sender);//Testing if i_owner is msg.sender. It failed because I called FundMeTest and FundMeTest deployed FundMe meaning FundMeTest is the owner of FundMe
        //assertEq(fundMe.i_owner(), address(this));//I should be checking if i_owner is equal to this contract as explained above.
        assertEq(fundMe.getOwner(), msg.sender);
    }

    //What can we do to work with addresses outside our system?
    //1. Unit
    //    -Testing a specific part of our code
    //2. Integration
    //      -Testing how our code works with other parts of our code.
    //3. Forked
    //    -Testing our code on a simulated rea; environment
    //4. Staging
    //     -Testing our code in a real environment that is not production

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); //hey, the next line, should revert!
        //assert(This tx fails/reverts)
        //uint256 cat = 3; //This test will fail because this line doesn't fail.
        fundMe.fund(); //send 0 value is less than a Eth. we need a line like this that fails for th etest to pass, this fails because we did not pass a value.
    }

    function testFundUpdatesFundedDataStructure() public {
        // fundMe.fund{value: 10e18}();
        // uint256 amountFunded = fundMe.getAddressToAmountFunded(address(this));
        // assertEq(amountFunded, SEND_VALUE);

        //Above is the real deal below is for the prank, the USER after contract above
        vm.prank(USER); //The next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    } //in our tests we wanna know whonis sedning what transactions. we can use pranck to know who is sendimng what, only works with foundry and we tests.

    modifier funded() {
        //A modifier allows us to create a keyword that we can put right in the function declaration to add some functionality very quickly and easily.
        vm.prank(USER); //This line are used to fund so we can carry out test for any function atht as to do with funds.
        fundMe.fund{value: SEND_VALUE}(); //This line are used to fund so we can carry out test for any function atht as to do with funds.
        _;
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        //we wanna make sure on the owner can call the withdrawal function.
        vm.prank(USER); // we are gonna try to use the USER to withdraw it should revert as the USER is not the owner.
        vm.expectRevert(); //The line means that the next line should revert.
        fundMe.withdraw();
    }

    function testWithdrawalWithASingleFunder() public funded {
        //Arrange : Arrange the test, setup the test
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // To test for withdrawal we first wanna confirm what our balamnce is before we call withdrawa so we can compare it to our balance after withsraw. This line will get owner's starting balance.
        uint256 startingFundMeBalance = address(fundMe).balance; //The actual balance of the FundMe contract

        //Act: Then the action i want to test.
        //uint256 gasStart = gasleft(); // 1000  gasleft() built into solidity tells you gas left.
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); // c: 200   only the owner can make withdrawal.
        fundMe.withdraw(); //This is what we are testing we put it in the act section.

        // uint256 gasEnd = gasleft();  // 800
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; //tx.gasprice built into solidity tells you current gas price.
        // console.log(gasUsed);

        //Assert : Then asset the test.
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance); //this is means startingFundMeBalance plus startingOwnerBalance equals endingFundMeBalance. 
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10; //uint160 has the same amt of bytes as an address.
        uint160 startingFunderIndex = 1; //if you wanna use numbers to generate addresses those numbers have to be uint160
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE); //This line equal the two line above.
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //Arrange
        uint160 numberOfFunders = 10; //uint160 has the same amt of bytes as an address.
        uint160 startingFunderIndex = 1; //if you wanna use numbers to generate addresses those numbers have to be uint160
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            //vm.deal  deal new address some money
            hoax(address(i), SEND_VALUE); //hoax does prank and deal combine. 
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}
