// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleFactoryCreateRaffleTest is IntegrationTest {
    uint256 nftId = 1;

    function setUp() public virtual override {
        super.setUp();

        erc721Mock = _mockERC721(collectionCreator);
        changePrank(creator);
    }

    function test_RemoveClooverRaffleFromRegister() external {
        address raffle = _createDummyRaffle();

        assertEq(factory.getRegisteredRaffle()[0], raffle);

        changePrank(raffle);

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleFactoryEvents.RemovedFromRegister(raffle);

        factory.removeClooverRaffleFromRegister();

        assertEq(factory.getRegisteredRaffle().length, 0);
    }

    function test_RemoveClooverRaffleFromRegister_RevertWhen_CallerNotAREgisterRaffle(address caller) external {
        changePrank(caller);
        vm.expectRevert(Errors.NOT_WHITELISTED.selector);
        factory.removeClooverRaffleFromRegister();
    }
}
