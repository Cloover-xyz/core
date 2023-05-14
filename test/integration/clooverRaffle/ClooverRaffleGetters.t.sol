// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleGettersTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();
        changePrank(creator);
    }

    function test_MaxTotalSupply(
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase
    ) external {
        ticketPrice = _boundTicketPrice(ticketPrice);
        ticketSalesDuration = _boundDuration(ticketSalesDuration);
        maxTotalSupply = uint16(_boundAmountNotZeroUnderOf(maxTotalSupply, MAX_TICKET_SUPPLY));
        ClooverRaffle raffle = _createRaffle(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            0,
            0
        );
        assertEq(raffle.maxTotalSupply(), maxTotalSupply);
    }

    function test_CurrentSupply(
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase
    ) external {
        nftId = _boundAmountNotZero(nftId);
        ticketPrice = _boundTicketPrice(ticketPrice);
        ticketSalesDuration = _boundDuration(ticketSalesDuration);
        maxTotalSupply = uint16(_boundAmountNotZeroUnderOf(maxTotalSupply, MAX_TICKET_SUPPLY));
        ClooverRaffle raffle = _createRaffle(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            0,
            0
        );

        assertEq(raffle.currentSupply(), 0);

        changePrank(participant);

        uint16 ticketToPurchase = uint16(bound(0, 1, maxTotalSupply));
        erc20Mock.mint(participant, ticketPrice * ticketToPurchase);
        erc20Mock.approve(address(raffle), ticketPrice * ticketToPurchase);

        raffle.purchaseTickets(ticketToPurchase);

        assertEq(raffle.currentSupply(), 1);
    }

    function test_Creator(address caller) external {
        caller = _boundAddressNotZero(caller);
        changePrank(caller);
        uint256 nft = 100;
        erc721Mock.mint(caller, nft);
        erc721Mock.approve(address(factory), nft);
        ClooverRaffle raffle =
            _createRaffle(address(erc20Mock), address(erc721Mock), nft, 1e18, 1 days, 10_000, 0, 0, 0);

        assertEq(raffle.creator(), caller);
    }

    function test_PurchaseCurrency(address purchaseCurrency) external {
        changePrank(maintainer);
        tokenWhitelist.addToWhitelist(purchaseCurrency);
        changePrank(creator);
        ClooverRaffle raffle =
            _createRaffle(purchaseCurrency, address(erc721Mock), nftId, 1e18, 1 days, 10_000, 0, 0, 0);

        assertEq(raffle.purchaseCurrency(), purchaseCurrency);
    }

    function test_TicketPrice(uint256 ticketPrice) external {
        ticketPrice = _boundTicketPrice(ticketPrice);
        ClooverRaffle raffle =
            _createRaffle(address(erc20Mock), address(erc721Mock), nftId, ticketPrice, 1 days, 10_000, 0, 0, 0);

        assertEq(raffle.ticketPrice(), ticketPrice);
    }

    function test_EndTicketSales(bool isEthRaffle, bool hasInsurance, bool hasRoyaties) external {
        (ClooverRaffle raffle, uint64 ticketSalesDuration) = _createRandomRaffle(isEthRaffle, hasInsurance, hasRoyaties);

        assertEq(raffle.endTicketSales(), block.timestamp + ticketSalesDuration);
    }

    function test_WinningTicketNumber_ReturnZeroWhen_NotTicketDrawn(
        bool isEthRaffle,
        bool hasInsurance,
        bool hasRoyaties
    ) external {
        (ClooverRaffle raffle,) = _createRandomRaffle(isEthRaffle, hasInsurance, hasRoyaties);
        assertEq(raffle.winningTicketNumber(), 0);
    }

    function test_WinnerAddress_ReturnAddressZeroWhen_NotTicketDrawn(
        bool isEthRaffle,
        bool hasInsurance,
        bool hasRoyaties
    ) external {
        (ClooverRaffle raffle,) = _createRandomRaffle(isEthRaffle, hasInsurance, hasRoyaties);
        assertEq(raffle.winnerAddress(), address(0));
    }

    function test_NftInfo(uint256 nftId) external {
        nftId = _boundAmountAboveOf(nftId, 1000);
        erc721Mock.mint(creator, nftId);
        erc721Mock.approve(address(factory), nftId);
        ClooverRaffle raffle =
            _createRaffle(address(erc20Mock), address(erc721Mock), nftId, 1e18, 1 days, 10_000, 0, 0, 0);
        (address nftContractAddress, uint256 nftId_) = raffle.nftInfo();
        assertEq(nftContractAddress, address(erc721Mock));
        assertEq(nftId_, nftId);
    }

    function test_RaffleStatus() external {
        ClooverRaffle raffle =
            _createRaffle(address(erc20Mock), address(erc721Mock), nftId, 1e18, 1 days, 10_000, 0, 0, 0);

        assertEq(uint256(raffle.raffleStatus()), 0);
    }

    function test_IsEthRaffle_OnTokenRaffle() external {
        ClooverRaffle raffle =
            _createRaffle(address(erc20Mock), address(erc721Mock), nftId, 1e18, 1 days, 10_000, 0, 0, 0);
        assertFalse(raffle.isEthRaffle());
    }

    function test_IsEthRaffle_OnEthRaffle() external {
        ClooverRaffle raffle = _createRaffle(address(0), address(erc721Mock), nftId, 1e18, 1 days, 10_000, 0, 0, 0);
        assertTrue(raffle.isEthRaffle());
    }

    function test_BalanceOf(
        address buyer,
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase
    ) external {
        buyer = _boundAddressNotZero(buyer);
        ticketPrice = _boundTicketPrice(ticketPrice);
        ticketSalesDuration = _boundDuration(ticketSalesDuration);
        maxTotalSupply = uint16(_boundAmountNotZeroUnderOf(maxTotalSupply, MAX_TICKET_SUPPLY));
        ClooverRaffle raffle = _createRaffle(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            0,
            0
        );

        changePrank(buyer);
        uint16 ticketToPurchase = _purchaseRandomAmountOfTickets(raffle, buyer, maxTotalSupply);
        uint16[] memory tickets = raffle.balanceOf(buyer);
        assertEq(tickets.length, ticketToPurchase);
        for (uint16 i = 0; i < ticketToPurchase; i++) {
            assertEq(tickets[i], i + 1);
        }
    }

    function test_BalanceOf_ReturnEmptyArrayWhen_NoTicketPurchased(address buyer) external {
        ClooverRaffle raffle =
            _createRaffle(address(erc20Mock), address(erc721Mock), nftId, 1e18, 1 days, 10_000, 0, 0, 0);

        uint16[] memory tickets = raffle.balanceOf(buyer);
        assertEq(tickets.length, 0);
    }

    function test_OwnerOf(
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase
    ) external {
        ticketPrice = _boundTicketPrice(ticketPrice);
        ticketSalesDuration = _boundDuration(ticketSalesDuration);
        maxTotalSupply = uint16(_boundAmountNotZeroUnderOf(maxTotalSupply, MAX_TICKET_SUPPLY));
        ClooverRaffle raffle = _createRaffle(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            0,
            0
        );

        changePrank(participant);
        uint16 ticketToPurchase = _purchaseRandomAmountOfTickets(raffle, participant, maxTotalSupply);
        assertEq(raffle.ownerOf(0), address(0));
        for (uint16 i = 1; i <= ticketToPurchase; i++) {
            assertEq(raffle.ownerOf(i), participant);
        }
        assertEq(raffle.ownerOf(ticketToPurchase + 1), address(0));
    }

    function test_RandomProvider() external {
        ClooverRaffle raffle =
            _createRaffle(address(erc20Mock), address(erc721Mock), nftId, 1e18, 1 days, 10_000, 0, 0, 0);

        assertEq(raffle.randomProvider(), address(randomProviderMock));
    }

    function test_Version() external {
        ClooverRaffle raffle =
            _createRaffle(address(erc20Mock), address(erc721Mock), nftId, 1e18, 1 days, 10_000, 0, 0, 0);
        assertEq(raffle.version(), "1");
    }
}
