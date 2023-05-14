// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleFactoryCreateRaffleTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();

        changePrank(creator);
    }

    function test_RemoveClooverRaffleFromRegister(bool isEthRaffle) external {
        (ClooverRaffle raffle,) = _createRandomRaffle(isEthRaffle, false, false);

        assertEq(factory.getRegisteredRaffle()[0], address(raffle));

        changePrank(address(raffle));

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleFactoryEvents.RemovedFromRegister(address(raffle));

        factory.removeClooverRaffleFromRegister();

        assertEq(factory.getRegisteredRaffle().length, 0);
    }

    function test_RemoveClooverRaffleFromRegister_RevertWhen_CallerNotAREgisterRaffle(address caller) external {
        changePrank(caller);
        vm.expectRevert(Errors.NOT_WHITELISTED.selector);
        factory.removeClooverRaffleFromRegister();
    }
}
