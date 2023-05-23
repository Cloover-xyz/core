// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleFactoryRemoveClooverRaffleFromRegisterTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();
        _deployClooverRaffleFactory();

        erc721Mock.mint(creator, nftId);
        changePrank(creator);
    }

    function test_RemoveClooverRaffleFromRegister() external {
        raffle = _createRaffle(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            0
        );

        assertEq(factory.getRegisteredRaffle()[0], address(raffle));

        changePrank(address(raffle));

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleFactoryEvents.RemovedFromRegister(address(raffle));

        factory.removeClooverRaffleFromRegister();

        assertEq(factory.getRegisteredRaffle().length, 0);
    }

    function test_RemoveClooverRaffleFromRegister_RevertWhen_CallerNotARaffleRegistered(address caller) external {
        changePrank(caller);
        vm.expectRevert(Errors.NOT_WHITELISTED.selector);
        factory.removeClooverRaffleFromRegister();
    }
}
