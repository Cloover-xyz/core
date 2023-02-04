// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library RaffleDataTypes {

    struct RaffleData {
        address creator;
        IERC20 purchaseCurrency;
        IERC721 nftContract;
        uint256 nftId;
        uint256 maxTicketSupply;
        uint256 ticketSupply;
        uint256 ticketPrice;
        uint256 winningTicketNumber;
        uint64 endTime;
        bool isTicketDrawn;
    }

    struct InitRaffleParams {
        address creator;
        IERC20 purchaseCurrency;
        IERC721 nftContract;
        uint256 nftId;
        uint256 maxTicketSupply;
        uint256 ticketPrice;
        uint64 endTime;
    }
}