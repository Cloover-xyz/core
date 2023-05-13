// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/RaffleTest.sol";

contract ClooverRaffleCancelTest is RaffleTest {
    function setUp() public virtual override {
        super.setUp();

        changePrank(creator);
    }

    function test_CancelRaffle(bool isEthRaffle, bool hasInsurance) external {
        (raffle,) = _createRandomRaffle(isEthRaffle, hasInsurance, false);

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.CANCELLED);
        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.RaffleCancelled();
        raffle.cancelRaffle();
        assertEq(erc20Mock.balanceOf(address(raffle)), 0);
        assertEq(address(raffle).balance, 0);
        assertEq(erc721Mock.ownerOf(nftId), creator);
    }

    function test_CancelRaffle_WhenStatusIsAlreadyCancelled(bool isEthRaffle, bool hasInsurance) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, hasInsurance, false);

        _forwardByTimestamp(ticketSalesDuration + 1);
        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.CANCELLED);
        raffle.draw();

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.RaffleCancelled();
        raffle.cancelRaffle();
        assertEq(erc20Mock.balanceOf(address(raffle)), 0);
        assertEq(address(raffle).balance, 0);
        assertEq(erc721Mock.ownerOf(nftId), creator);
    }

    function test_CancelRaffle_RevertWhen_NotCreatorCalling(bool isEthRaffle, bool hasInsurance, address caller)
        external
    {
        (raffle,) = _createRandomRaffle(isEthRaffle, hasInsurance, false);

        changePrank(caller);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        raffle.cancelRaffle();
    }

    function test_CancelRaffle_RevertWhen_AtLeastOneTicketHasBeenSold(bool isEthRaffle, bool hasInsurance) external {
        (raffle,) = _createRandomRaffle(isEthRaffle, hasInsurance, false);

        changePrank(participant1);
        uint16 maxTotalSupply = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTickets(raffle, participant1, maxTotalSupply);

        changePrank(creator);
        vm.expectRevert(Errors.SALES_ALREADY_STARTED.selector);
        raffle.cancelRaffle();
    }

    function test_CancelRaffle_RefundInsurancePaid(bool isEthRaffle) external {
        (raffle,) = _createRandomRaffle(isEthRaffle, true, false);

        uint256 insurancePaid = raffle.insurancePaid();
        uint256 balanceBefore;
        if (isEthRaffle) {
            balanceBefore = address(creator).balance;
        } else {
            balanceBefore = erc20Mock.balanceOf(address(creator));
        }
        raffle.cancelRaffle();
        if (isEthRaffle) {
            assertEq(address(creator).balance, balanceBefore + insurancePaid);
        } else {
            assertEq(erc20Mock.balanceOf(address(creator)), balanceBefore + insurancePaid);
        }
    }
}
