// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {ClooverRaffleDataTypes} from '../libraries/types/ClooverRaffleDataTypes.sol';
import {ClooverRaffle} from '../raffle/ClooverRaffle.sol';

interface IClooverRaffleFactory {
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
     * @param params used for initialization (see Params struct in ClooverRaffleFactory.sol)
     * @return newClooverRaffle the instance of the raffle contract
     */
    function createNewClooverRaffle(Params memory params) external payable returns(ClooverRaffle newClooverRaffle);


    /**
     * @notice Return if the address is a raffle deployed by this factory
     * @param raffleAddress the address to check
     * @return bool is true if it's a raffle deployed by this factory, false otherwise
     */
    function isRegisteredClooverRaffle(address raffleAddress) external view returns (bool);

    /**
     * @notice call by batch draw() for each raffleContract passed
     * @param raffleContracts the array of raffle addresses to call draw()
     */
    function batchClooverRaffledraw(address[] memory raffleContracts) external;

    /**
     * @notice remove msg.sender from the list of registered raffles
     */
    function deregisterClooverRaffle() external;
    
    /**
     * @notice return the version of the contract
     */
    function version() external pure returns(string memory);
}