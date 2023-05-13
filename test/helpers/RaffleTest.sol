// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {PercentageMath} from "src/libraries/PercentageMath.sol";

import "./IntegrationTest.sol";

contract RaffleTest is IntegrationTest {
    using InsuranceLib for uint16;

    uint256 nftId = 1;

    ClooverRaffle raffle;

    function setUp() public virtual override {
        super.setUp();

        erc721Mock = _mockERC721(collectionCreator);
        erc20Mock = _mockERC20(18);

        sigUtils = new SigUtils(erc20Mock.DOMAIN_SEPARATOR());

        erc721Mock.mint(creator, nftId);
        changePrank(creator);
    }

    function _createRaffle(
        address purchaseCurrency,
        address nftContract,
        uint256 nftId_,
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase,
        uint16 ticketSalesInsurance,
        uint16 royaltiesRate
    ) internal returns (ClooverRaffle) {
        erc721Mock.approve(address(factory), nftId_);

        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            purchaseCurrency,
            nftContract,
            nftId_,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            ticketSalesInsurance,
            royaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        if (ticketSalesDuration > 0) {
            uint256 insuranceCost = ticketSalesInsurance.calculateInsuranceCost(INSURANCE_RATE, ticketPrice);
            if (purchaseCurrency == address(0)) {
                return ClooverRaffle(factory.createNewRaffle{value: insuranceCost}(params, permitData));
            }
            erc20Mock.mint(creator, insuranceCost);
            erc20Mock.approve(address(factory), insuranceCost);
        }
        return ClooverRaffle(factory.createNewRaffle(params, permitData));
    }

    function _createRandomRaffle(bool isEthRaffle, bool hasInsurance, bool hasRoyalties)
        internal
        returns (ClooverRaffle, uint64)
    {
        uint256 ticketPrice = _boundTicketPrice(1e18);
        uint64 ticketSalesDuration = _boundDuration(1 days);
        uint16 maxTotalSupply = uint16(bound(100, 100, MAX_TICKET_SUPPLY));
        uint16 maxTicketAllowedToPurchase = uint16(_boundAmountUnderOf(0, maxTotalSupply));

        uint16 ticketSalesInsurance = 0;
        uint16 royaltiesRate = 0;
        if (hasInsurance) {
            if (maxTicketAllowedToPurchase > 10) {
                ticketSalesInsurance = uint16(_boundAmountNotZeroUnderOf(2, maxTicketAllowedToPurchase));
            } else {
                maxTicketAllowedToPurchase = 0;
                ticketSalesInsurance = uint16(_boundAmountNotZeroUnderOf(2, maxTotalSupply));
            }
        }
        if (hasRoyalties) {
            royaltiesRate =
                uint16(_boundPercentageUnderOf(1, uint16(PercentageMath.PERCENTAGE_FACTOR - PROTOCOL_FEE_RATE)));
        }

        ClooverRaffle _raffle = _createRaffle(
            isEthRaffle ? address(0) : address(erc20Mock),
            address(erc721Mock),
            nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            ticketSalesInsurance,
            royaltiesRate
        );

        return (_raffle, ticketSalesDuration);
    }

    function _purchaseRandomAmountOfTickets(ClooverRaffle _raffle, address buyer, uint16 maxTicketToPurchase)
        internal
        returns (uint16 ticketToPurchase)
    {
        changePrank(buyer);
        bool isEthRaffle = _raffle.isEthRaffle();
        uint256 ticketPrice = _raffle.ticketPrice();
        ticketToPurchase = uint16(_boundAmountNotZeroUnderOf(1, maxTicketToPurchase));
        uint256 amount = ticketPrice * ticketToPurchase;
        if (isEthRaffle) {
            _raffle.purchaseTicketsInEth{value: amount}(ticketToPurchase);
        } else {
            erc20Mock.mint(buyer, amount);
            erc20Mock.approve(address(_raffle), amount);

            _raffle.purchaseTickets(ticketToPurchase);
        }
        return ticketToPurchase;
    }

    function _purchaseRandomAmountOfTicketsBetween(
        ClooverRaffle _raffle,
        address buyer,
        uint16 minTicketToPurchase,
        uint16 maxTicketToPurchase
    ) internal returns (uint16 ticketToPurchase) {
        changePrank(buyer);
        bool isEthRaffle = _raffle.isEthRaffle();
        uint256 ticketPrice = _raffle.ticketPrice();
        uint16 maxTicketAllowedToPurchase = _raffle.maxTicketAllowedToPurchase();
        if (maxTicketAllowedToPurchase > 0) {
            ticketToPurchase = uint16(bound(1, minTicketToPurchase, maxTicketAllowedToPurchase));
        } else {
            ticketToPurchase = uint16(bound(1, minTicketToPurchase, maxTicketToPurchase));
        }

        uint256 amount = ticketPrice * ticketToPurchase;
        if (isEthRaffle) {
            _raffle.purchaseTicketsInEth{value: amount}(ticketToPurchase);
        } else {
            erc20Mock.mint(buyer, amount);
            erc20Mock.approve(address(_raffle), amount);

            _raffle.purchaseTickets(ticketToPurchase);
        }
        return ticketToPurchase;
    }

    function _purchaseExactAmountOfTickets(ClooverRaffle _raffle, address buyer, uint16 ticketToPurchase) internal {
        changePrank(buyer);
        bool isEthRaffle = _raffle.isEthRaffle();
        uint256 ticketPrice = _raffle.ticketPrice();
        uint256 amount = ticketPrice * ticketToPurchase;
        if (isEthRaffle) {
            _raffle.purchaseTicketsInEth{value: amount}(ticketToPurchase);
        } else {
            erc20Mock.mint(buyer, amount);
            erc20Mock.approve(address(_raffle), amount);

            _raffle.purchaseTickets(ticketToPurchase);
        }
    }
}
