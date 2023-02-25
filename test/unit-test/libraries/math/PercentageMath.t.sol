// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";


import {PercentageMath} from "../../../../src/libraries/math/PercentageMath.sol";


contract PercentageMathTest is Test {
    using PercentageMath for uint256;

    function test_CorrectlyMulPercentage() external {
        uint256 amount = 100e18;
        assertEq(amount.percentMul(1e3), 1e19); // 10%
        assertEq(amount.percentMul(1e5), 1e21); // 1000%
    }
    
    function test_CorrectlyDivPercentage() external {
        uint256 amount = 100e18;
        assertEq(amount.percentDiv(1e3), 1e21); // 10%
        assertEq(amount.percentDiv(1e5), 1e19); // 1000%
    }

    function test_RevertIf_PercentageIsZero() external {
        uint256 amount = 100e18;
        vm.expectRevert();
        amount.percentMul(0);
        amount.percentDiv(0);
    }

    function test_RevertIf_OverFlow() external {
        uint256 amount = type(uint256).max;
        uint256 percentage = 1e3; // 10%
        vm.expectRevert();
        amount.percentMul(percentage);
        amount.percentDiv(percentage);
    }
}