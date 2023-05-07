// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {ClooverRaffleDataTypes} from '../libraries/types/ClooverRaffleDataTypes.sol';

interface IClooverRaffle {
    /**
     * @notice Function to initialize contract
     * @dev must be tag by the initializer function 
     * @param params used for initialization (see InitClooverRaffleParams struct)
     */
    function initialize(ClooverRaffleDataTypes.InitializeRaffleParams memory params) external payable;

    /**
     * @notice Allows users to purchase tickets
     * @dev Only callable if ticket sales still open
     * @param nbOfTickets number of tickets to purchase
     */
    function purchaseTickets(uint16 nbOfTickets) external;

    /**
     * @notice Allows users to purchase tickets using ERC20Permit
     * @dev Only callable if ticket sales still open
     * @param nbOfTickets number of tickets to purchase
     * @param permitData data used for the ETC20permit
     */
    function purchaseTicketsWithPermit(uint16 nbOfTickets, ClooverRaffleDataTypes.PermitData calldata permitData) external;

    /**
     * @notice Allows users to purchase tickets with ETH
     * @dev Only callable if ticket sales still open
     * @param nbOfTickets number of tickets to purchase
     */
    function purchaseTicketsInEth(uint16 nbOfTickets) external payable;
    
    /**
     * @notice Request a random numbers
     * @dev must call the RandomProvider that use Chainlink's VRFConsumerBaseV2
     */
    function draw() external;

    /**
     * @notice Select the winning ticket number using the random number from Chainlink's VRFConsumerBaseV2
     * @dev must be only called by the RandomProvider contract
     * function must not revert to avoid multi drawn to revert and block contract in case of wrong value received
     * @param randomNumbers random numbers requested in array
     */
    function draw(uint256[] memory randomNumbers) external;
    
    /**
     * @notice Allows the creator to exerce the insurance he paid for and claim back his nft
     * @dev Only callable if ticket sales is close and amount of ticket sold is lower than raffle insurance
     * in case no ticket has been sold, the creator can claim back his nft with the insurance he paid
     * Only callable if raffle is in ERC20
     */
    function creatorClaimInsurance() external;

    /**
     * @notice Allows the creator to exerce the insurance he paid for and claim back his nft
     * @dev Only callable if ticket sales is close and amount of ticket sold is lower than raffle insurance
     * in case no ticket has been sold, the creator can claim back his nft with the insurance he paid
     * Only callable if raffle is in Eth
     */
    function creatorClaimInsuranceInEth() external;

    /**
     * @notice Allows the creator to claim the amount related to the ticket sales
     * @dev The functions should send to the creator his part after fees
     * In case creator paid insurance, the function should send the insurance to the creator
     * Only callable if raffle is in ERC20
     */
    function creatorClaimTicketSales() external;

    /**
     * @notice Allows the creator to claim the amount related to the ticket sales
     * @dev The functions should send to the creator his part after fees
     * In case creator paid insurance, the function should send the insurance to the creator
     * Only callable if tickets has been sold in Eth
     */
    function creatorClaimTicketSalesInEth() external;

    /**
     * @notice Allows the winner to claim his price
     * @dev Ticket sales must be over and winning ticket drawn
     */
    function winnerClaim() external;

   /**
    * @notice Allow tickets owner to claim refund if raffle is in insurance mode
    * @dev Only callable if ticket sales is over and amount of ticket sold is lower than insurance defined by creator
    * user must receive the amount he paid for his tickets + a part of the insurance
    * Only callable if tickets has been sold in Tokens 
    */
    function userClaimRefund() external;

   /**
    * @notice Allow tickets owner to claim refund if raffle is in insurance mode
    * @dev Only callable if ticket sales is over and amount of ticket sold is lower than insurance defined by creator
    * user must receive the amount he paid for his tickets + a part of the insurance
     * Only callable if tickets has been sold in Eth 
    */
    function userClaimRefundInEth() external;

    /**
     * @notice Allow the creator to cancel the raffle
     * @dev Only callable if no ticket has been sold
     * must sent back the nft to the creator
     * must refund the creator insurance if paid
     * must remove the raffle from the ClooverRaffleFactory whitelist
     */
    function cancelRaffle() external;

    /**
    * @notice get the total amount of tickets sold
    * @return The total amount of tickets sold
    */
    function currentSupply() external view returns(uint16);

    /**
    * @notice get the max amount of tickets that can be sold
    * @return The total amount of tickets sold
    */
    function maxTotalSupply() external view returns(uint16);

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
    * @notice get if the raffle accept only ETH
    * @return The True if ticket can only be purchase in ETH, False otherwise
    */
    function isEthRaffle() external view returns(bool);

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
    function winningTicket() external view returns(uint16);
    
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
    * @notice get info regarding the workflow status of the raffle
    * @return The status regarding the RaffleStatus enum 
    */
    function raffleStatus() external view returns(ClooverRaffleDataTypes.RaffleStatus);

    /**
    * @notice get all tickets number bought by a user
    * @return True if ticket has been drawn, False otherwise
    */
    function balanceOf(address user) external view returns(uint16[] memory);

    /**
    * @notice get the wallet that bought a specific ticket number
    * @return The address that bought the own the ticket
    */
    function ownerOf(uint16 id) external view returns(address);

   /**
    * @notice get the randomProvider contract address from the implementationManager
    * @return The address of the randomProvider contract
    */
    function randomProvider() external view returns(address);
    
    /**
     * @notice return the version of the contract
     */
    function version() external pure returns(string memory);
}