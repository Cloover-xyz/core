// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./IntegrationTest.sol";

contract FuzzTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();

        erc721Mock.mint(creator, nftId);
        erc721Mock.approve(address(factory), nftId);
    }

    function _createFuzzRaffle(
        bool isEthRaffle,
        bool hasInsurance,
        bool hasRoyalties,
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTicketSupply,
        uint16 maxTicketPerWallet,
        uint16 minTicketThreshold,
        uint16 royaltiesRate
    ) internal returns (ClooverRaffle) {
        ticketPrice = _boundTicketPrice(ticketPrice);
        ticketSalesDuration = _boundDuration(ticketSalesDuration);
        maxTicketSupply = _boundMaxTotalSupply(maxTicketSupply);

        maxTicketPerWallet = uint16(_boundAmountUnderOf(0, maxTicketSupply));
        royaltiesRate = uint16(_boundAmountUnderOf(royaltiesRate, PercentageMath.PERCENTAGE_FACTOR - PROTOCOL_FEE_RATE));

        if (hasInsurance) {
            if (maxTicketPerWallet > 10) {
                minTicketThreshold = uint16(_boundAmountNotZeroUnderOf(2, maxTicketPerWallet));
            } else {
                maxTicketPerWallet = 0;
                minTicketThreshold = uint16(_boundAmountNotZeroUnderOf(2, maxTicketSupply));
            }
        } else {
            minTicketThreshold = 0;
        }
        if (hasRoyalties) {
            royaltiesRate =
                uint16(_boundPercentageUnderOf(1, uint16(PercentageMath.PERCENTAGE_FACTOR - PROTOCOL_FEE_RATE)));
        } else {
            royaltiesRate = 0;
        }

        return _createRaffle(
            isEthRaffle ? address(0) : address(erc20Mock),
            address(erc721Mock),
            nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTicketSupply,
            maxTicketPerWallet,
            minTicketThreshold,
            royaltiesRate
        );
    }

    function _boundCommonCreateRaffleParams(uint256 ticketPrice, uint64 ticketSalesDuration, uint16 maxTicketSupply)
        internal
        view
        returns (uint256 _ticketPrice, uint64 _ticketSalesDuration, uint16 _maxTotalSupply)
    {
        _ticketPrice = _boundTicketPrice(ticketPrice);
        _ticketSalesDuration = _boundDuration(ticketSalesDuration);
        _maxTotalSupply = _boundMaxTotalSupply(maxTicketSupply);
    }

    function _boundTicketPrice(uint256 ticketPrice) internal view returns (uint256) {
        return bound(ticketPrice, MIN_TICKET_PRICE, MAX_AMOUNT);
    }

    function _boundDuration(uint64 duration) internal view returns (uint64) {
        return uint64(bound(duration, MIN_SALE_DURATION, MAX_SALE_DURATION));
    }

    function _boundDurationUnderOf(uint64 duration, uint64 max) internal view returns (uint64) {
        return uint64(bound(duration, 0, max - 1));
    }

    function _boundDurationAboveOf(uint64 duration, uint64 min) internal view returns (uint64) {
        return uint64(bound(duration, min + 1, type(uint64).max));
    }

    function _assumeNotMaintainer(address caller) internal view {
        caller = _boundAddressNotZero(caller);
        vm.assume(caller != maintainer);
    }

    function _boundMaxTotalSupply(uint16 maxTicketSupply) internal view returns (uint16) {
        return uint16(bound(maxTicketSupply, 100, MAX_TICKET_SUPPLY));
    }

    function _boundTicketSalesInsurance(uint16 amount, uint16 maxTicketPerWallet) internal view returns (uint16) {
        return uint16(_boundAmountNotZeroUnderOf(amount, maxTicketPerWallet));
    }

    function _boundEthAmount(uint256 amount) internal view virtual returns (uint256) {
        return bound(amount, 1, INITIAL_BALANCE);
    }
}
