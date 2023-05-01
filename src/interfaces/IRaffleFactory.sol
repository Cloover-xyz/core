// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {RaffleDataTypes} from '../libraries/types/RaffleDataTypes.sol';
import {Raffle} from '../raffle/Raffle.sol';

interface IRaffleFactory {
    struct Params {
        IERC20 purchaseCurrency;
        IERC721 nftContract;
        uint256 nftId;
        uint256 maxTicketSupply;
        uint256 ticketPrice;
        uint256 minTicketSalesInsurance;
        uint64 ticketSaleDuration;
        bool isETHTokenSales;
        uint256 maxTicketAllowedToPurchase;
        uint256 royaltiesPercentage;
    }

    /**
     * @notice Deploy a new raffle contract
     * @dev must transfer the nft to the contract before initialize()
     * @param params used for initialization (see Params struct in RaffleFactory.sol)
     * @return newRaffle the instance of the raffle contract
     */
    function createNewRaffle(Params memory params) external payable returns(Raffle newRaffle);


    /**
     * @notice Return if the address is a raffle deployed by this factory
     * @param raffleAddress the address to check
     * @return bool is true if it's a raffle deployed by this factory, false otherwise
     */
    function isRegisteredRaffle(address raffleAddress) external view returns (bool);

    /**
     * @notice call by batch draw() for each raffleContract passed
     * @param raffleContracts the array of raffle addresses to call draw()
     */
    function batchRaffledraw(address[] memory raffleContracts) external;

    /**
     * @notice remove msg.sender from the list of registered raffles
     */
    function deregisterRaffle() external;
    
    /**
     * @notice return the version of the contract
     */
    function version() external pure returns(string memory);
}