// SPDX-License-Identifier: MIT    

pragma solidity ^0.8.19; 

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundeMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 10e18; // 10 ETH in wei
    uint256 constant SEND_ETH = 10e15; // 10 ETH in wei
    uint256 constant GAS_PRICE = 1e9; // 1 Gwei




   function setUp() public {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // Give USER 10 ETH
    }

    function testMinimumDollarIsFive() public view {
         assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getversion();
        assertEq(version, 4);
    }

    function testFundMeFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund(); // This will fail because no ETH is sent fund{value:0}()
    }

    function testFundingUpdatesFundDataStructure() public {
        vm.prank(USER); //this txn wuld be sent by USER
        fundMe.fund{value:SEND_ETH }();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded,SEND_ETH );
    }

    function testAddFunderToArrayOnFund() public {
        vm.prank(USER); //this txn wuld be sent by USER
        fundMe.fund{value:SEND_ETH }();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER); //this txn wuld be sent by USER
        fundMe.fund{value:SEND_ETH }();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded{
        vm.prank(USER); //this txn wuld be sent by USER
        vm.expectRevert();
        fundMe.withdraw(); // USER tries to withdraw, but should fail
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingUserBalance = USER.balance;

        //Act
        vm.prank(fundMe.getOwner()); //this txn wuld be sent by owner
        fundMe.withdraw();

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingUserBalance = USER.balance;

        //Assert
        assertEq(endingFundMeBalance, 0);
        assertApproxEqAbs(startingFundMeBalance + startingUserBalance, endingUserBalance, 1e16); // 1e15 is a tolerance for gas fees
    }   

     function testcheapWithdrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingUserBalance = USER.balance;

        //Act
        vm.prank(fundMe.getOwner()); //this txn wuld be sent by owner
        fundMe.cheapwithdraw();

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingUserBalance = USER.balance;

        //Assert
        assertEq(endingFundMeBalance, 0);
        assertApproxEqAbs(startingFundMeBalance + startingUserBalance, endingUserBalance, 1e16); // 1e15 is a tolerance for gas fees
    } 

    function testWithdrawWithMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunders = 1; // We already have USER as a funder
        for (uint160 i = startingFunders; i < numberOfFunders; i++) {
            hoax(address(i), SEND_ETH); // Create a new address and send SEND_ETH to it
            fundMe.fund{value: SEND_ETH}();
        }
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        //Act
        vm.prank(fundMe.getOwner()); //this txn wuld be sent by owner
        fundMe.withdraw();

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;

        //Assert
        assertEq(endingFundMeBalance, 0);
        assertApproxEqAbs(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance,
            1e16
        ); // 1e15 is a tolerance for gas fees
    }
}
