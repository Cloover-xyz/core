// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleFactoryGettersTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();
        _deployClooverRaffleFactory();

        erc721Mock.mint(creator, nftId);
        changePrank(creator);
    }

    function test_ProtocolFeeRate() external {
        assertEq(factory.protocolFeeRate(), PROTOCOL_FEE_RATE);
    }

    function test_InsuranceRate() external {
        assertEq(factory.insuranceRate(), INSURANCE_RATE);
    }

    function test_MinTicketSalesDuration() external {
        assertEq(factory.minTicketSalesDuration(), MIN_SALE_DURATION);
    }

    function test_MaxTicketSalesDuration() external {
        assertEq(factory.maxTicketSalesDuration(), MAX_SALE_DURATION);
    }

    function test_MaxTotalSupplyAllowed() external {
        assertEq(factory.maxTicketSupplyAllowed(), MAX_TICKET_SUPPLY);
    }

    function test_ImplementationManager() external {
        assertEq(address(factory.implementationManager()), address(implementationManager));
    }

    function test_TicketSalesDurationLimits() external {
        (uint256 minDuration, uint256 maxDuration) = factory.ticketSalesDurationLimits();
        assertEq(minDuration, MIN_SALE_DURATION);
        assertEq(maxDuration, MAX_SALE_DURATION);
    }

    function test_IsRegistered() external {
        assertEq(factory.isRegistered(address(0)), false);
    }

    function test_GetRegisteredRaffle() external {
        assertEq(factory.getRegisteredRaffle().length, 0);

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

        assertEq(factory.getRegisteredRaffle().length, 1);
        assertEq(factory.getRegisteredRaffle()[0], address(raffle));
    }

    function test_Version() external {
        assertEq(factory.version(), "1");
    }
}
