// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


import {IRaffle} from "../interfaces/IRaffle.sol";
import {IRandomProvider} from "../interfaces/IRandomProvider.sol";

import {RaffleDataTypes} from "./RaffleDataTypes.sol";
import {RaffleStorage} from "./RaffleStorage.sol";
 
contract Raffle is IRaffle, RaffleStorage, Initializable {

    //----------------------------------------
    // Events
    //----------------------------------------

    event TicketPurchased(address indexed raffleContract, address indexed buyer, uint256[] ticketNumbers);
    event WinnerClaimedPrice(address indexed raffleContract, address indexed winner, address indexed nftContract, uint256 nftId);
    event CreatorClaimTicketSalesAmount(address indexed raffleContract, address indexed winner, uint256 amountReceived);
    event WinningTicketDrawned(address indexed raffleContract, uint256 winningTicket);
      
    //----------------------------------------
    // Modifier
    //----------------------------------------

    modifier ticketSalesOpen() {
        if(block.timestamp >= _globalData.endTicketSales) revert Errors.RAFFLE_CLOSE();
        _;
    }
    modifier ticketSalesClose() {
        if(block.timestamp < _globalData.endTicketSales) revert Errors.RAFFLE_STILL_OPEN();
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
    
    modifier onlyRandomProviderContract(){
        if(_globalData.implementationManager.getImplementationAddress(ImplementationInterfaceNames.RandomProvider) != msg.sender) revert Errors.NOT_RANDOM_PROVIDER_CONTRACT();
        _;
    }

    //----------------------------------------
    // Initialize function
    //----------------------------------------
    function initialize(RaffleDataTypes.InitRaffleParams memory _params) external override initializer {
        _checkData(_params);
        _globalData.implementationManager = _params.implementationManager;
        _globalData.creator = _params.creator;
        _globalData.purchaseCurrency = _params.purchaseCurrency;
        _globalData.nftContract = _params.nftContract;
        _globalData.nftId = _params.nftId;
        _globalData.maxTicketSupply = _params.maxTicketSupply;
        _globalData.ticketPrice = _params.ticketPrice;
        _globalData.endTicketSales = uint64(block.timestamp) + _params.ticketSaleDuration;
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
            ++ticketNumber;
            ticketsPurchased[i] = ticketNumber;
            ownerTickets.push(ticketNumber);
            _ticketOwner[ticketNumber] = msg.sender;
            unchecked {
                ++i;
            }
        }
        _globalData.ticketSupply = ticketNumber;
        emit TicketPurchased(address(this), msg.sender, ticketsPurchased);
    }

    /// @inheritdoc IRaffle
    function drawnRandomTickets() external override ticketSalesClose() ticketHasNotBeDrawn() {
        IRandomProvider(_globalData.implementationManager.getImplementationAddress(ImplementationInterfaceNames.RandomProvider)).requestRandomNumbers(1);
    }

    /// @inheritdoc IRaffle
    function drawnTickets(uint256[] memory randomNumbers) external override ticketSalesClose() ticketHasNotBeDrawn() onlyRandomProviderContract(){
        if(randomNumbers[0] == 0 || randomNumbers.length == 0) revert Errors.CANT_BE_ZERO();
        _globalData.winningTicketNumber = randomNumbers[0] % _globalData.ticketSupply;
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
    * @notice get the end time where ticket sales closing
    * @return The time in timestamps
    */
    function endTicketSales() public view returns(uint64) {
        return _globalData.endTicketSales;
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
    * @notice check that initialize data are correct
    * @param _params the struct data use for initialization
    */
    function _checkData(RaffleDataTypes.InitRaffleParams memory _params) internal view {
        if(address(_params.implementationManager) == address(0)) revert Errors.NOT_ADDRESS_0();
        if(address(_params.purchaseCurrency) == address(0)) revert Errors.NOT_ADDRESS_0();
        if(_params.nftContract.ownerOf(_params.nftId) != address(this)) revert Errors.NOT_NFT_OWNER();
        if(_params.creator == address(0)) revert Errors.NOT_ADDRESS_0();
        if(_params.ticketPrice == 0) revert Errors.CANT_BE_ZERO();
        if(_params.maxTicketSupply == 0) revert Errors.CANT_BE_ZERO();
        if(_params.ticketSaleDuration == 0) revert Errors.CANT_BE_ZERO();
    }

    /**
    * @notice calculate the total price that must be paid regarding the amount of tickets to buy
    * @return amountPrice the total cost
    */
    function _calculateTotalTicketsPrice(uint256 nbOfTickets) internal view returns(uint256 amountPrice) {
        amountPrice = _globalData.ticketPrice * nbOfTickets;
    }
}