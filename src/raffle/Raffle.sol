// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {Errors} from "../libraries/helpers/Errors.sol";
import {IRaffle} from "../interfaces/IRaffle.sol";

import {RaffleDataTypes} from "./RaffleDataTypes.sol";
import {RaffleStorage} from "./RaffleStorage.sol";
 
contract Raffle is IRaffle, RaffleStorage, Initializable {

    //----------------------------------------
    // Events
    //----------------------------------------

    event NewRaffle(address indexed raffleContract, RaffleDataTypes.RaffleData globalData);
    event TicketPurchased(address indexed raffleContract, address indexed buyer, uint256[] ticketNumbers);
    event WinnerClaimedPrice(address indexed raffleContract, address indexed winner, address indexed nftContract, uint256 nftId);
    event CreatorClaimTicketSalesAmount(address indexed raffleContract, address indexed winner, uint256 amountReceived);
    event WinningTicketDrawned(address indexed raffleContract, uint256 winningTicket);
      
    //----------------------------------------
    // Modifier
    //----------------------------------------

    modifier ticketSalesOpen() {
        if(block.timestamp >= _globalData.endTime) revert Errors.RAFFLE_CLOSE();
        _;
    }
    modifier ticketSalesClose() {
        if(block.timestamp < _globalData.endTime) revert Errors.RAFFLE_STILL_OPEN();
        _;
    }

    modifier ticketHasNotBeDrawn(){
        if(isTicketDrawn()) revert Errors.TICKET_ALREADY_DRAWN();
        _;
    }

    modifier ticketHasBeDrawn(){
        if(!isTicketDrawn()) revert Errors.TICKET_NOT_DRAWN();
        _;
    }

    //----------------------------------------
    // Initialize function
    //----------------------------------------
    function initialize(RaffleDataTypes.InitRaffleParams memory _data) external initializer {
        _data.nftContract.transferFrom(_data.creator, address(this), _data.nftId);

        _globalData.creator = _data.creator;
        _globalData.purchaseCurrency = _data.purchaseCurrency;
        _globalData.nftContract = _data.nftContract;
        _globalData.nftId = _data.nftId;
        _globalData.maxTicketSupply = _data.maxTicketSupply;
        _globalData.ticketPrice = _data.ticketPrice;
        _globalData.endTime = uint64(block.timestamp) + _data.endTime;

        emit NewRaffle(address(this), _globalData);
    }

    //----------------------------------------
    // Externals Functions
    //----------------------------------------

    /// @inheritdoc IRaffle
    function purchaseTickets(uint256 nbOfTickets) external override ticketSalesOpen(){
        if(nbOfTickets == 0) revert Errors.CANT_BE_ZERO();
        if(totalSupply() + nbOfTickets > _globalData.maxTicketSupply) revert Errors.MAX_TICKET_SUPPLY_EXCEEDED();
        if(_calculateTotalTicketsPrice(nbOfTickets) > _globalData.purchaseCurrency.balanceOf(msg.sender)) revert Errors.NOT_ENOUGH_BALANCE();
        
        _globalData.purchaseCurrency.transferFrom(msg.sender, address(this), _calculateTotalTicketsPrice(nbOfTickets));

        uint256[] storage ownerTickets = _ownerTickets[msg.sender];
        uint256 ticketNumber = _globalData.ticketSupply;

        uint256[] memory ticketsPurchased = new uint256[](nbOfTickets);
        for(uint i; i<nbOfTickets; ){
            ticketsPurchased[i] = ticketNumber;
            ownerTickets.push(ticketNumber);
            _ticketOwner[ticketNumber] = msg.sender;
            unchecked {
                ++ticketNumber;
                ++i;
            }
        }
        _globalData.ticketSupply = ticketNumber;
        emit TicketPurchased(address(this), msg.sender, ticketsPurchased);
    }

    /// @inheritdoc IRaffle
    function drawnTicket() external override ticketSalesClose() ticketHasNotBeDrawn() {
        uint256 randomNumber = uint256(blockhash(block.number - 1));
        _globalData.winningTicketNumber = (randomNumber % _globalData.ticketSupply);
        _globalData.isTicketDrawn = true;
        emit WinningTicketDrawned(address(this), _globalData.winningTicketNumber );
    }

    /// @inheritdoc IRaffle
    function claimPrice() external override ticketSalesClose() ticketHasBeDrawn(){
        if(msg.sender != winnerAddress()) revert Errors.MSG_SENDER_NOT_WINNER();
        _globalData.nftContract.safeTransferFrom(address(this), msg.sender,_globalData.nftId);
        emit WinnerClaimedPrice(address(this), msg.sender, address(_globalData.nftContract), _globalData.nftId);
    }

    /// @inheritdoc IRaffle
    function claimTicketSalesAmount() external override ticketSalesClose() ticketHasBeDrawn(){
        if(msg.sender != creator()) revert Errors.NOT_CREATOR();
        uint256 amount = _globalData.purchaseCurrency.balanceOf(address(this));
        _globalData.purchaseCurrency.transfer(msg.sender, amount);
        emit CreatorClaimTicketSalesAmount(address(this), msg.sender, amount);
    }

    /**
    * @notice get the total amount of tickets sold
    * @return The total amount of tickets sold
    */
    function totalSupply() public view returns(uint256) {
        return _globalData.ticketSupply;
    }

    /**
    * @notice get the max amount of tickets that can be sold
    * @return The total amount of tickets sold
    */
    function maxSupply() public view returns(uint256) {
        return _globalData.maxTicketSupply;
    }

    /**
    * @notice get the address of the wallet that initiated the raffle
    * @return The address of the creator
    */
    function creator() public view returns(address) {
        return _globalData.creator;
    }

    /**
    * @notice get the address of the token used to buy tickets
    * @return The address of the ERC20
    */
    function purchaseCurrency() public view returns(IERC20) {
        return _globalData.purchaseCurrency;
    }

    /**
    * @notice get the price of one ticket
    * @return The amount of token that one ticket cost
    */
    function ticketPrice() public view returns(uint256) {
        return _globalData.ticketPrice;
    }

   /**
    * @notice get the end time before ticket sales closing
    * @return The time in timestamps
    */
    function endTime() public view returns(uint64) {
        return _globalData.endTime;
    }
    
    /**
    * @notice get the winning ticket number
    * @dev revert if ticket sales not close and if ticket number hasn't be drawn
    * @return The ticket number that win the raffle
    */
    function winningTicket() public ticketSalesClose() ticketHasBeDrawn() view returns(uint256) {
        return _globalData.winningTicketNumber;
    }
    
    /**
    * @notice get the winner address
    * @dev revert if ticket sales not close and if ticket number hasn't be drawn
    * @return The address of the wallet that won the raffle
    */
    function winnerAddress() public ticketSalesClose() ticketHasBeDrawn() view returns(address) {
        return _ticketOwner[_globalData.winningTicketNumber];
    }

    /**
    * @notice get the information regarding the nft to win
    * @return nftContractAddress The address of the nft
    * @return nftId The id of the nft
    */
    function nftToWin() public view returns(IERC721 nftContractAddress, uint256 nftId) {
        return (_globalData.nftContract, _globalData.nftId);
    }

    /**
    * @notice get info if the winning ticket has been drawn
    * @return True if ticket has been drawn, False otherwise
    */
    function isTicketDrawn() public view returns(bool) {
        return _globalData.isTicketDrawn;
    }

    /**
    * @notice get all tickets number bought by a user
    * @return True if ticket has been drawn, False otherwise
    */
    function balanceOf(address user) external view returns(uint256[] memory){
        return _ownerTickets[user];
    }

     /**
    * @notice get the wallet that bought a specific ticket number
    * @return The address that bought the own the ticket
    */
    function ownerOf(uint256 id) external view returns(address){
        return _ticketOwner[id];
    }

    //----------------------------------------
    // Internals Functions
    //----------------------------------------

    /**
    * @notice calculate the total price that must be paid regarding the amount of tickets to buy
    * @return amountPrice the total cost
    */
    function _calculateTotalTicketsPrice(uint256 nbOfTickets) internal view returns(uint256 amountPrice) {
        amountPrice = _globalData.ticketPrice * nbOfTickets;
    }
}