// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20, SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";

import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/Errors.sol";
import {ClooverRaffleEvents} from "../libraries/Events.sol";
import {ClooverRaffleTypes} from "../libraries/Types.sol";
import {PercentageMath} from "../libraries/PercentageMath.sol";
import {InsuranceLib} from "../libraries/InsuranceLib.sol";

import {ClooverRaffleStorage} from "./ClooverRaffleStorage.sol";

/// @title ClooverRaffleInternal
/// @author Cloover
/// @notice Abstract contract exposing `Raffle`'s internal functions.
abstract contract ClooverRaffleInternal is ClooverRaffleStorage {
    using PercentageMath for uint256;
    using InsuranceLib for uint16;
    using SafeTransferLib for ERC20;

    //----------------------------------------
    // Internal functions
    //----------------------------------------

    /// @notice handle the purchase of tickets in ERC20
    function _purchaseTicketsInToken(uint16 nbOfTickets) internal {
        if (_config.isEthRaffle) revert Errors.IS_ETH_RAFFLE();

        uint256 ticketCost = _calculateTicketsCost(nbOfTickets);

        _purchaseTickets(nbOfTickets);

        ERC20(_config.purchaseCurrency).safeTransferFrom(msg.sender, address(this), ticketCost);
    }

    /// @notice attribute ticket to msg.sender
    function _purchaseTickets(uint16 nbOfTickets) internal {
        if (nbOfTickets == 0) revert Errors.CANT_BE_ZERO();

        uint16 maxTicketAllowedToPurchase = _config.maxTicketAllowedToPurchase;
        if (
            maxTicketAllowedToPurchase > 0
                && _participantInfoMap[msg.sender].nbOfTicketsPurchased + nbOfTickets > maxTicketAllowedToPurchase
        ) {
            revert Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE();
        }

        uint16 currentSupply = _lifeCycleData.currentSupply;
        if (currentSupply + nbOfTickets > _config.maxTotalSupply) {
            revert Errors.TICKET_SUPPLY_OVERFLOW();
        }

        uint16 purchasedEntriesIndex = uint16(_purchasedEntries.length);
        uint16 currentTicketsSold = _lifeCycleData.currentSupply + nbOfTickets;

        ClooverRaffleTypes.PurchasedEntries memory entryPurchase = ClooverRaffleTypes.PurchasedEntries({
            owner: msg.sender,
            currentTicketsSold: currentTicketsSold,
            nbOfTickets: nbOfTickets
        });
        _purchasedEntries.push(entryPurchase);

        _participantInfoMap[msg.sender].nbOfTicketsPurchased += nbOfTickets;
        _participantInfoMap[msg.sender].purchasedEntriesIndexes.push(purchasedEntriesIndex);

        _lifeCycleData.currentSupply = currentTicketsSold;

        emit ClooverRaffleEvents.TicketsPurchased(msg.sender, currentSupply, nbOfTickets);
    }

    /// @notice calculate the amount to transfer to the creator, protocol and royalties
    function _calculateAmountToTransfer(uint256 totalBalance)
        internal
        view
        returns (uint256 creatorAmount, uint256 protocolFeesAmount, uint256 royaltiesAmount)
    {
        uint256 insuranceCost = _calculateInsuranceCost();
        uint256 ticketSalesAmount = totalBalance - insuranceCost;
        protocolFeesAmount = ticketSalesAmount.percentMul(_config.protocolFeeRate);
        royaltiesAmount = ticketSalesAmount.percentMul(_config.royaltiesRate);
        creatorAmount = ticketSalesAmount - protocolFeesAmount - royaltiesAmount + insuranceCost;
    }

    /// @notice check raffle can be in insurance mode and return the amount to transfer to the treasury and its address
    function _handleCreatorInsurance() internal returns (uint256 treasuryAmountToTransfer, address treasuryAddress) {
        uint16 ticketSalesInsurance = _config.ticketSalesInsurance;
        if (ticketSalesInsurance == 0) revert Errors.NO_INSURANCE_TAKEN();
        uint16 currentSupply = _lifeCycleData.currentSupply;
        if (currentSupply == 0) revert Errors.NOTHING_TO_CLAIM();

        if (currentSupply >= ticketSalesInsurance) {
            revert Errors.SALES_EXCEED_INSURANCE_LIMIT();
        }

        _lifeCycleData.status = ClooverRaffleTypes.Status.INSURANCE;

        (treasuryAmountToTransfer,) = ticketSalesInsurance.splitInsuranceAmount(
            _config.insuranceRate, _config.protocolFeeRate, currentSupply, _config.ticketPrice
        );
        treasuryAddress = IImplementationManager(_config.implementationManager).getImplementationAddress(
            ImplementationInterfaceNames.Treasury
        );
    }

    function _calculateUserRefundAmount() internal returns (uint256 totalRefundAmount) {
        if (_lifeCycleData.currentSupply >= _config.ticketSalesInsurance) revert Errors.SALES_EXCEED_INSURANCE_LIMIT();

        ClooverRaffleTypes.ParticipantInfo memory participantInfo = _participantInfoMap[msg.sender];
        if (participantInfo.hasClaimedRefund) revert Errors.ALREADY_CLAIMED();
        _participantInfoMap[msg.sender].hasClaimedRefund = true;

        uint256 nbOfTicketPurchased = participantInfo.nbOfTicketsPurchased;
        if (nbOfTicketPurchased == 0) revert Errors.NOTHING_TO_CLAIM();

        totalRefundAmount =
            _calculateTicketsCost(nbOfTicketPurchased) + _calculateUserInsurancePart(nbOfTicketPurchased);
    }

    /// @notice calculate the amount of insurance assign to the user
    function _calculateUserInsurancePart(uint256 nbOfTicketPurchased)
        internal
        view
        returns (uint256 userAmountToReceive)
    {
        (, uint256 amountPerTicket) = _config.ticketSalesInsurance.splitInsuranceAmount(
            _config.insuranceRate, _config.protocolFeeRate, _lifeCycleData.currentSupply, _config.ticketPrice
        );
        userAmountToReceive = amountPerTicket * nbOfTicketPurchased;
    }

    /// @notice calculate the amount of insurance paid by the creator
    function _calculateInsuranceCost() internal view returns (uint256 insuranceCost) {
        if (_config.ticketSalesInsurance == 0) return 0;
        insuranceCost = _config.ticketSalesInsurance.calculateInsuranceCost(_config.insuranceRate, _config.ticketPrice);
    }

    /// @notice calculate the total price that must be paid regarding the amount of tickets to buy
    function _calculateTicketsCost(uint256 nbOfTickets) internal view returns (uint256 amountPrice) {
        amountPrice = _config.ticketPrice * nbOfTickets;
    }

    /// @notice return the address of the winner
    function _winnerAddress() internal view returns (address) {
        if (_lifeCycleData.winningTicketNumber == 0) return address(0);
        uint256 index = findUpperBound(_purchasedEntries, _lifeCycleData.winningTicketNumber);
        return _purchasedEntries[index].owner;
    }

    /// @notice Searches a sorted `array` and returns the first index that contains the `ticketNumberToSearch`
    /// https://docs.openzeppelin.com/contracts/3.x/api/utils#Arrays-findUpperBound-uint256---uint256-
    function findUpperBound(ClooverRaffleTypes.PurchasedEntries[] memory array, uint256 ticketNumberToSearch)
        internal
        pure
        returns (uint256)
    {
        if (array.length == 0) return 0;

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (array[mid].currentTicketsSold > ticketNumberToSearch) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        if (low > 0 && array[low - 1].currentTicketsSold == ticketNumberToSearch) {
            return low - 1;
        } else {
            return low;
        }
    }
}
