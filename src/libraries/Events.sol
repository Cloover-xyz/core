// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ClooverRaffleTypes} from "./ClooverRaffleTypes.sol";

/// @title ClooverRaffleEvents
/// @author Cloover
/// @notice Library exposing events used in ClooverRaffle.
library ClooverRaffleEvents {
    /// @notice Emitted when a purchase tickets happens.
    /// @param user The address of the user that purchased tickets
    /// @param firstTicketnumber The first ticket number purchased at the call (use to calculate tickets number purchased)
    /// @param nbOfTicketsPurchased The number of tickets purchased
    event TicketsPurchased(address indexed user, uint16 firstTicketnumber, uint16 nbOfTicketsPurchased);

    /// @notice Emitted when a user claim his price.
    event WinnerClaimed(address winner);

    /// @notice Emitted when the creator claim tickets sales.
    /// @param creatorAmountReceived The amount received by the creator
    /// @param protocolFeeAmount The amount received by the protocol
    /// @param royaltiesAmount The amount received by the nft collection creator as royalties
    event CreatorClaimed(uint256 creatorAmountReceived, uint256 protocolFeeAmount, uint256 royaltiesAmount);

    /// @notice Emitted when the random ticket number is drawn.
    event WinningTicketDrawn(uint16 winningTicket);

    /// @notice Emitted when the creator exercise his insurance.
    event CreatorClaimedInsurance();

    /// @notice Emitted when the user claim his refund.
    /// @param user The address of the user that claimed his refund
    /// @param amountReceived The amount received by the user (refund + his insurance part)
    event UserClaimedRefund(address indexed user, uint256 amountReceived);

    /// @notice Emitted when the raffle is cancelled by the creator
    event RaffleCancelled();

    /// @notice Emitted when the raffle status is updated
    event RaffleStatus(ClooverRaffleTypes.Status indexed status);
}

/// @title ClooverRaffleFactoryEvents
/// @author Cloover
/// @notice Library exposing events used in ClooverRaffleFactory.
library ClooverRaffleFactoryEvents {
    /// @notice Emitted when a new raffle is created
    event NewRaffle(address indexed raffleContract, ClooverRaffleTypes.InitializeRaffleParams raffleParams);

    /// @notice Emitted when a raffle contract is removed from register
    event RemovedFromRegister(address indexed raffleContract);

    /// @notice Emitted when protocol fee rate is updated
    event ProtocolFeeRateUpdated(uint256 newProtocolFeeRate);

    /// @notice Emitted when insurance rate is updated
    event InsuranceRateUpdated(uint256 newInsuranceRate);

    /// @notice Emitted when max total supply allowed is updated
    event MaxTotalSupplyAllowedUpdated(uint256 newMaxTicketSupply);

    /// @notice Emitted when min ticket sales duration is updated
    event MinTicketSalesDurationUpdated(uint256 newMinTicketSalesDuration);

    /// @notice Emitted when max ticket sales duration is updated
    event MaxTicketSalesDurationUpdated(uint256 newMaxTicketSalesDuration);
}
