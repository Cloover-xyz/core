// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {PercentageMath} from "src/libraries/PercentageMath.sol";

import "test/helpers/BaseTest.sol";

contract PercentageMathTest is BaseTest {
    using PercentageMath for uint256;

    function test_PercentMul() external {
        uint256 amount = 100e18;
        assertEq(amount.percentMul(10_00), 1e19); // 10%
        assertEq(amount.percentMul(1_000_00), 1e21); // 1000%
    }
    
    function test_PercentMul_RevertWhen_OverFlow() external {
        uint256 amount = type(uint256).max;
        uint256 percentage = 10_00; // 10%
        vm.expectRevert();
        amount.percentMul(percentage);
        
    }

    function test_PercentDiv() external {
        uint256 amount = 100e18;
        assertEq(amount.percentDiv(10_00), 1e21); // 10%
        assertEq(amount.percentDiv(1_000_00), 1e19); // 1000%
    }

    function test_PercentDiv_RevertWhen_ValueIsZero() external {
        uint256 amount = 100e18;
        vm.expectRevert();
        amount.percentDiv(0);
    }

    function test_PercentDiv_RevertWhen_OverFlow() external {
        uint256 amount = type(uint256).max;
        uint256 percentage = 10_00; // 10%
        vm.expectRevert();
        amount.percentDiv(percentage);
    }
}