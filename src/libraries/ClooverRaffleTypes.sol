// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";

/// @title ClooverRaffleTypes
/// @author Cloover
/// @notice Library exposing all Types used in ClooverRaffle.
library ClooverRaffleTypes {
    
    /* ENUMS */
    /// @notice Enumeration of the different status of the raffle
    enum Status {
        DEFAULT,
        DRAWNING,
        DRAWN,
        INSURANCE,
        CANCELLED
    }

    /* STORAGE STRUCTS */
    
    /// @notice Contains the immutable config of a raffle
    struct ConfigData {
        address creator;    
        IImplementationManager implementationManager;
        IERC20 purchaseCurrency;
        IERC721 nftContract;
        uint256 nftId;
        uint256 ticketPrice;
        uint64 endTicketSales;
        uint16 maxTotalSupply;
        uint16 maxTicketAllowedToPurchase;
        uint16 ticketSalesInsurance;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint16 royaltiesRate;
        bool isEthRaffle;
    }


    /// @notice Contains the current state of the raffle
    struct LifeCycleData {
        Status status;
        uint16 currentSupply;
        uint16 winningTicketNumber;
    }

    /// @notice Contains the info of a purchased entry
    struct PurchasedEntries{
        address owner;
        uint16 currentTicketsSold; // Current amount of tickets sold with new purchase
        uint16 nbOfTickets; // number of tickets purchased
    }

    ///@notice Contains the info of a participant
    struct ParticipantInfo{
        uint16 nbOfTicketsPurchased;
        uint16[] purchasedEntriesIndexes;
        bool hasClaimedRefund;
    }
 
    /// @notice Contains the base info and limit for raffles
    struct FactoryConfig{
        uint16 maxTotalSupplyAllowed;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint64 minTicketSalesDuration;
        uint64 maxTicketSalesDuration;
    }


    
    /* STACK AND RETURN STRUCTS */

    /// @notice The parameters used by the raffle factory to create a new raffle
    struct CreateRaffleParams{
        IERC20 purchaseCurrency;
        IERC721 nftContract;
        uint256 nftId;
        uint256 ticketPrice;
        uint64 ticketSalesDuration;
        uint16 maxTotalSupply;
        uint16 maxTicketAllowedToPurchase;
        uint16 ticketSalesInsurance;
        uint16 royaltiesRate;
        PermitDataParams permitData;
    }

    /// @notice The parameters used for ERC20 permit function
    struct PermitDataParams{
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice The parameters used to initialize the raffle
    struct InitializeRaffleParams {
        address creator;    
        IImplementationManager implementationManager;
        IERC20 purchaseCurrency;
        IERC721 nftContract;
        uint256 nftId;
        uint256 ticketPrice;
        uint64 ticketSalesDuration;
        uint16 maxTotalSupply;
        uint16 maxTicketAllowedToPurchase;
        uint16 ticketSalesInsurance;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint16 royaltiesRate;
        bool isEthRaffle;
    }

    /// @notice The parameters used to initialize the raffle factory
    struct FactoryConfigParams{
        uint16 maxTotalSupplyAllowed;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint64 minTicketSalesDuration;
        uint64 maxTicketSalesDuration;
    }
}