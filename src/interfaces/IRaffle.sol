// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {RaffleDataTypes} from '../raffle/RaffleDataTypes.sol';

interface IRaffle {
    /**
     * @notice Function to initialize contract
     * @dev must be tag by the initializer function 
     * @param _params used for initialization (see InitRaffleParams struct)
     */
    function initialize(RaffleDataTypes.InitRaffleParams memory _params) external;

    /**
     * @notice Allows users to purchase tickets
     * @dev Only accessible if raffle still open to particpants
     * @param nbOfTickets number of tickets purchased
     */
    function purchaseTickets(uint256 nbOfTickets) external;

    /**
     * @notice Allows the winner to claim his price
     * @dev Ticket number must be draw and raffle close to new participants
     */
    function claimPrice() external;
    
    /**
     * @notice Allows the creator to claim the amount related to the ticket sales
     * @dev The functions should send to the creator his part after fees
     */
    function claimTicketSalesAmount() external;
    
    /**
     * @notice Request a random numbers
     * @dev must call the RandomProvider that use ChainLinkVRFv2 
     */
    function drawnTickets() external;

    /**
     * @notice Select the winning tickets number received from the RandomProvider contract
     * @dev must be only called by the RandomProvider contract or the RaffleFactory
     * @dev function must not revert to avoid multi drawn to be reverted
     * @param randomNumbers random numbers requested in array
     */
    function drawnTickets(uint256[] memory randomNumbers) external;

      /**
    * @notice get the total amount of tickets sold
    * @return The total amount of tickets sold
    */
    function totalSupply() external view returns(uint256);

    /**
    * @notice get the max amount of tickets that can be sold
    * @return The total amount of tickets sold
    */
    function maxSupply() external view returns(uint256);

    /**
    * @notice get the address of the wallet that initiated the raffle
    * @return The address of the creator
    */
    function creator() external view returns(address);

    /**
    * @notice get the address of the token used to buy tickets
    * @return The address of the ERC20
    */
    function purchaseCurrency() external view returns(IERC20);

    /**
    * @notice get the price of one ticket
    * @return The amount of token that one ticket cost
    */
    function ticketPrice() external view returns(uint256);

   /**
    * @notice get the end time where ticket sales closing
    * @return The time in timestamps
    */
    function endTicketSales() external view returns(uint64);
    
    /**
    * @notice get the winning ticket number
    * @dev revert if ticket sales not close and if ticket number hasn't be drawn
    * @return The ticket number that win the raffle
    */
    function winningTicket() external view returns(uint256);
    
    /**
    * @notice get the winner address
    * @dev revert if ticket sales not close and if ticket number hasn't be drawn
    * @return The address of the wallet that won the raffle
    */
    function winnerAddress() external view returns(address);

    /**
    * @notice get the information regarding the nft to win
    * @return nftContractAddress The address of the nft
    * @return nftId The id of the nft
    */
    function nftToWin() external view returns(IERC721 nftContractAddress, uint256 nftId);

    /**
    * @notice get info if the winning ticket has been drawn
    * @return True if ticket has been drawn, False otherwise
    */
    function isTicketDrawn() external view returns(bool);

    /**
    * @notice get all tickets number bought by a user
    * @return True if ticket has been drawn, False otherwise
    */
    function balanceOf(address user) external view returns(uint256[] memory);

    /**
    * @notice get the wallet that bought a specific ticket number
    * @return The address that bought the own the ticket
    */
    function ownerOf(uint256 id) external view returns(address);

   /**
    * @notice get the randomProvider contract address from the implementationManager
    * @return The address of the randomProvider contract
    */
    function randomProvider() external view returns(address);
    
   /**
    * @notice get the raffleFactory contract address from the implementationManager
    * @return The address of the raffleFactory contract
    */
    function raffleFactory() external view returns(address);
}