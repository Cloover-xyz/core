// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleGettersTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();
        changePrank(creator);
    }

    function test_MaxTotalSupply() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            assertEq(raffle.maxTotalSupply(), initialMaxTotalSupply);
        }
    }

    function test_CurrentSupply() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            assertEq(raffle.currentSupply(), 0);
            _purchaseExactAmountOfTickets(raffle, participant, 1);
            assertEq(raffle.currentSupply(), 1);
        }
    }

    function test_Creator() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            assertEq(raffle.creator(), creator);
        }
    }

    function test_PurchaseCurrency() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (isEthRaffle) {
                assertEq(raffle.purchaseCurrency(), address(0));
            } else {
                assertEq(raffle.purchaseCurrency(), address(erc20Mock));
            }
        }
    }

    function test_TicketPrice() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            assertEq(raffle.ticketPrice(), initialTicketPrice);
        }
    }

    function test_EndTicketSales() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            assertEq(raffle.endTicketSales(), block.timestamp + initialTicketSalesDuration);
        }
    }

    function test_WinningTicketNumber_ReturnZeroWhen_NotTicketDrawn() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            assertEq(raffle.winningTicketNumber(), 0);
        }
    }

    function test_WinnerAddress_ReturnAddressZeroWhen_NotTicketDrawn() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            assertEq(raffle.winnerAddress(), address(0));
        }
    }

    function test_NftInfo() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            (address nftContractAddress, uint256 nftId_) = raffle.nftInfo();
            assertEq(nftContractAddress, address(erc721Mock));
            assertEq(nftId_, nftId);
        }
    }

    function test_RaffleStatus() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            assertEq(uint256(raffle.raffleStatus()), 0);
        }
    }

    function test_IsEthRaffle_OnTokenRaffle() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (isEthRaffle) continue;

            assertFalse(raffle.isEthRaffle());
        }
    }

    function test_IsEthRaffle_OnEthRaffle() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (!isEthRaffle) continue;

            assertTrue(raffle.isEthRaffle());
        }
    }

    function test_BalanceOf_ReturnEmptyArrayWhen_NoTicketPurchased() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            uint16[] memory tickets = raffle.balanceOf(participant);
            assertEq(tickets.length, 0);
        }
    }

    function test_BalanceOf() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            uint16 nbOfTicketsPurchased = 8;
            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);

            uint16[] memory tickets = raffle.balanceOf(participant);
            assertEq(tickets.length, nbOfTicketsPurchased);
            for (uint16 j = 0; j < nbOfTicketsPurchased; j++) {
                assertEq(tickets[j], j + 1);
            }
        }
    }

    function test_OwnerOf() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            uint16 nbOfTicketsPurchased = 8;
            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);
            assertEq(raffle.ownerOf(0), address(0));

            for (uint16 j = 1; j < nbOfTicketsPurchased; j++) {
                assertEq(raffle.ownerOf(j), participant);
            }
            assertEq(raffle.ownerOf(nbOfTicketsPurchased + 1), address(0));
        }
    }

    function test_RandomProvider() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            assertEq(raffle.randomProvider(), address(randomProviderMock));
        }
    }

    function test_Version() external {
        for (uint16 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            assertEq(raffle.version(), "1");
        }
    }
}
