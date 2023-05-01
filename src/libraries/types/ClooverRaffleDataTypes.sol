// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {IImplementationManager} from "../../interfaces/IImplementationManager.sol";

library ClooverRaffleDataTypes {

    enum ClooverRaffleStatus {
        DEFAULT,
        DRAWNING,
        DRAWN,
        INSURANCE,
        CANCELLED
    }

    struct ClooverRaffleData {
        address creator;
        IERC20 purchaseCurrency;
        IImplementationManager implementationManager;
        IERC721 nftContract;
        uint256 nftId;
        uint256 maxTicketSupply;
        uint256 ticketSupply;
        uint256 ticketPrice;
        uint256 winningTicketNumber;
        uint256 minTicketSalesInsurance;
        uint64 endTicketSales;
        bool isEthTokenSales;
        ClooverRaffleStatus status;
        uint256 maxTicketAllowedToPurchase;
        uint256 protocolFeesPercentage;
        uint256 insuranceSalesPercentage;
        uint256 royaltiesPercentage;
    }
 
    struct InitClooverRaffleParams {
        IImplementationManager implementationManager;
        IERC20 purchaseCurrency;
        IERC721 nftContract;
        address creator;
        uint256 nftId;
        uint256 maxTicketSupply;
        uint256 ticketPrice;
        uint256 minTicketSalesInsurance;
        uint64 ticketSaleDuration;
        bool isEthTokenSales;
        uint256 maxTicketAllowedToPurchase;
        uint256 royaltiesPercentage;
    }
}