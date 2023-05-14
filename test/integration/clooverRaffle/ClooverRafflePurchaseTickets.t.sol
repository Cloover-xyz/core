// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRafflePurchaseTicketsTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();
        changePrank(creator);
    }

    function test_PurchaseTickets_TokenRaffle(uint16 nbOfTicketsPurchase) external {
        nbOfTicketsPurchase = uint16(bound(nbOfTicketsPurchase, 1, 100));
        uint256 ticketPrice = 1e18;
        ClooverRaffle raffle =
            _createRaffle(address(erc20Mock), address(erc721Mock), nftId, ticketPrice, 1 days, 100, 0, 0, 0);

        changePrank(participant);
        uint256 amount = ticketPrice * nbOfTicketsPurchase;
        erc20Mock.mint(participant, amount);
        erc20Mock.approve(address(raffle), amount);

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.TicketsPurchased(participant, 0, nbOfTicketsPurchase);
        raffle.purchaseTickets(nbOfTicketsPurchase);

        assertEq(raffle.currentSupply(), nbOfTicketsPurchase);
        assertEq(raffle.balanceOf(participant).length, nbOfTicketsPurchase);
    }

    function test_PurchaseTickets_TokenRaffleWithPermit(uint16 nbOfTicketsPurchase, uint256 privateKey) external {
        privateKey = bound(privateKey, 1, type(uint160).max);
        address buyer = vm.addr(privateKey);
        nbOfTicketsPurchase = uint16(bound(nbOfTicketsPurchase, 1, 100));
        uint256 ticketPrice = 1e18;
        ClooverRaffle raffle =
            _createRaffle(address(erc20Mock), address(erc721Mock), nftId, ticketPrice, 1 days, 100, 0, 0, 0);

        changePrank(buyer);

        uint256 amount = ticketPrice * nbOfTicketsPurchase;
        erc20Mock.mint(buyer, amount);

        ClooverRaffleTypes.PermitDataParams memory permitData = _signPermitData(privateKey, address(raffle), amount);

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.TicketsPurchased(buyer, 0, nbOfTicketsPurchase);
        raffle.purchaseTicketsWithPermit(nbOfTicketsPurchase, permitData);

        assertEq(raffle.currentSupply(), nbOfTicketsPurchase);
        assertEq(raffle.balanceOf(buyer).length, nbOfTicketsPurchase);
    }

    function test_PurchaseTickets_EthRaffle(uint16 nbOfTicketsPurchase) external {
        nbOfTicketsPurchase = uint16(bound(nbOfTicketsPurchase, 1, 100));
        uint256 ticketPrice = 1e18;
        ClooverRaffle raffle = _createRaffle(address(0), address(erc721Mock), nftId, ticketPrice, 1 days, 100, 0, 0, 0);

        changePrank(participant);
        uint256 amount = ticketPrice * nbOfTicketsPurchase;

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.TicketsPurchased(participant, 0, nbOfTicketsPurchase);
        raffle.purchaseTicketsInEth{value: amount}(nbOfTicketsPurchase);

        assertEq(raffle.currentSupply(), nbOfTicketsPurchase);
        assertEq(raffle.balanceOf(participant).length, nbOfTicketsPurchase);
    }

    function test_PurchaseTickets_TokenRaffle_RevertWhen_IsEthRaffle() external {
        ClooverRaffle raffle = _createRaffle(address(0), address(erc721Mock), nftId, 1e18, 1 days, 100, 0, 0, 0);

        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        raffle.purchaseTickets(1);
    }

    function test_PurchaseTickets_EthRaffle_RevertWhen_IsNotEthRaffle() external {
        ClooverRaffle raffle = _createRaffle(address(erc20Mock), address(erc721Mock), nftId, 1e18, 1 days, 100, 0, 0, 0);

        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        raffle.purchaseTicketsInEth(1);
    }

    function test_PurchaseTickets_TokenRaffle_RevertWhen_AmountPurchaseIsZero() external {
        ClooverRaffle raffle = _createRaffle(address(erc20Mock), address(erc721Mock), nftId, 1e18, 1 days, 100, 0, 0, 0);

        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        raffle.purchaseTickets(0);
    }

    function test_PurchaseTickets_EthRaffle_RevertWhen_AmountPurchaseIsZero() external {
        ClooverRaffle raffle = _createRaffle(address(0), address(erc721Mock), nftId, 1e18, 1 days, 100, 0, 0, 0);

        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        raffle.purchaseTicketsInEth(0);
    }

    function test_PurchaseTickets_RevertWhen_NbOfTicketPurchasedIsZero(
        uint16 maxTicketAllowedToPurchase,
        uint16 nbOfTicketsPurchase
    ) external {
        maxTicketAllowedToPurchase = uint16(bound(maxTicketAllowedToPurchase, 1, 50));
        nbOfTicketsPurchase = uint16(bound(nbOfTicketsPurchase, maxTicketAllowedToPurchase + 1, 100));
        uint256 ticketPrice = 1e18;
        ClooverRaffle raffle = _createRaffle(
            address(erc20Mock), address(erc721Mock), nftId, ticketPrice, 1 days, 100, maxTicketAllowedToPurchase, 0, 0
        );

        changePrank(participant);

        uint256 amount = ticketPrice * nbOfTicketsPurchase;
        erc20Mock.mint(participant, amount);
        erc20Mock.approve(address(raffle), amount);

        vm.expectRevert(Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE.selector);
        raffle.purchaseTickets(nbOfTicketsPurchase);
    }

    function test_PurchaseTickets_RevertWhen_NbOfTicketPurchasedMakeCurrentSupplyExceedMaxSupply(
        uint16 maxTicketSupply,
        uint16 nbOfTicketsPurchase
    ) external {
        maxTicketSupply = uint16(_boundAmountNotZeroUnderOf(maxTicketSupply, MAX_TICKET_SUPPLY));
        nbOfTicketsPurchase = uint16(_boundAmountAboveOf(nbOfTicketsPurchase, maxTicketSupply + 1));
        uint256 ticketPrice = 1e18;
        ClooverRaffle raffle =
            _createRaffle(address(erc20Mock), address(erc721Mock), nftId, ticketPrice, 1 days, maxTicketSupply, 0, 0, 0);

        changePrank(participant);

        uint256 amount = ticketPrice * nbOfTicketsPurchase;
        erc20Mock.mint(participant, amount);
        erc20Mock.approve(address(raffle), amount);

        vm.expectRevert(Errors.TICKET_SUPPLY_OVERFLOW.selector);
        raffle.purchaseTickets(nbOfTicketsPurchase);
    }

    function test_PurchaseTickets_EthRaffle_RevertWhen_ValueSentIsNotEqualToTicketsCost(uint16 nbOfTicketsPurchase)
        external
    {
        nbOfTicketsPurchase = uint16(bound(nbOfTicketsPurchase, 1, 100));
        uint256 ticketPrice = 1e18;

        ClooverRaffle raffle = _createRaffle(address(0), address(erc721Mock), nftId, 1e18, 1 days, 100, 0, 0, 0);

        changePrank(participant);
        uint256 amount = ticketPrice * nbOfTicketsPurchase;
        amount = bound(amount, amount + 1, INITIAL_BALANCE);

        vm.expectRevert(Errors.WRONG_MSG_VALUE.selector);
        raffle.purchaseTicketsInEth{value: amount}(nbOfTicketsPurchase);

        amount = _boundAmountUnderOf(amount, amount);
        vm.expectRevert(Errors.WRONG_MSG_VALUE.selector);
        raffle.purchaseTicketsInEth{value: amount}(nbOfTicketsPurchase);
    }

    function test_PurchaseTickets_TokenRaffle_RevertWhen_TicketSalesOver(uint64 saleDuration) external {
        saleDuration = _boundDuration(saleDuration);
        ClooverRaffle tokenRaffle =
            _createRaffle(address(erc20Mock), address(erc721Mock), nftId, 1e18, saleDuration, 100, 0, 0, 0);

        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));

        changePrank(participant);
        _forwardByTimestamp(saleDuration + 1);

        vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
        tokenRaffle.purchaseTickets(10);

        vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
        tokenRaffle.purchaseTicketsWithPermit(10, permitData);
    }

    function test_PurchaseTickets_EthRaffle_RevertWhen_TicketSalesOver(uint64 saleDuration) external {
        saleDuration = _boundDuration(saleDuration);

        ClooverRaffle ethRaffle =
            _createRaffle(address(0), address(erc721Mock), nftId, 1e18, saleDuration, 100, 0, 0, 0);
        changePrank(participant);
        _forwardByTimestamp(saleDuration + 1);

        vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
        ethRaffle.purchaseTicketsInEth{value: 10}(10);
    }
}
