// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ERC20, SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

contract UserMock {
    using SafeTransferLib for ERC20;

    uint256 internal constant DEFAULT_MAX_ITERATIONS = 10;
    
    uint256  private _privateKey;

    constructor(uint256 privateKey_) {
        _privateKey = privateKey_;
    }

    receive() external payable {}

    function balanceOf(address token) external view returns (uint256) {
        return ERC20(token).balanceOf(address(this));
    }

    function approve(address token, address spender, uint256 amount) external {
        ERC20(token).safeApprove(spender, amount);
    }

    function privateKey() external view returns(uint256) {
        return _privateKey;
    }

    function permit(
        address token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
  ) external {
    ERC20(token).permit(owner, spender, value, deadline, v, r, s);
  }
}