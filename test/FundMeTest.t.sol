// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    // the very first thing that runs before each test
    function setUp() external {
        // setUp is a special function name
        fundMe = new FundMe();
    }

    function testMinimumUsdIsFive() public view {
        assertEq(fundMe.MIN_USD(), 5e18); // assertEq comes from `Test` contract
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.i_owner(), address(this));
    }
}
