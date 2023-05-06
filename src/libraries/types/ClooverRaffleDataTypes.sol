// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {IImplementationManager} from "../../interfaces/IImplementationManager.sol";

library ClooverRaffleDataTypes {
    
    struct PermitData{
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct ConfigData {
        address creator;    
        IImplementationManager implementationManager;
        IERC20 purchaseCurrency;
        IERC721 nftContract;
        uint256 nftId;
        uint256 ticketPrice;
        uint64 endTicketSales;
        uint16 maxTotalSupply;
        uint16 ticketSalesInsurance;
        uint16 maxTicketAllowedToPurchase;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint16 royaltiesRate;
        bool isEthRaffle;

    }

    enum RaffleStatus {
        DEFAULT,
        DRAWNING,
        DRAWN,
        INSURANCE,
        CANCELLED
    }

    struct LifeCycleData {
        RaffleStatus status;
        uint16 currentSupply;
        uint16 winningTicketNumber;
    }

    struct PurchasedEntries{
        address owner;
        uint16 currentTicketsSold; // Current amount of tickets sold with new purchase
        uint16 nbOfTickets; // number of tickets purchased
    }

    struct ParticipantInfo{
        uint16 nbOfTicketsPurchased;
        uint16[] purchasedEntriesIndexes;
        bool hasClaimedRefund;
    }
 
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
        uint16 royaltiesRate;
    }

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
    }
}