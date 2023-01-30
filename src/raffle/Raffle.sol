// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
 
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {Errors} from "@libraries/helpers/Errors.sol";
import {IRaffle} from "@interfaces/IRaffle.sol";

import {RaffleDataTypes} from "./RaffleDataTypes.sol";
import {RaffleStorage} from "./RaffleStorage.sol";
 

contract Raffle is IRaffle, RaffleStorage, Initializable {

    event NewRaffle(address indexed raffleAddress, RaffleDataTypes.RaffleData globalData);
    event TicketPurchased(address indexed buyer, uint256[] ticketNumbers);
    event WinnerClaimedPrice(address indexed winner, address indexed nftContract, uint256 nftId);

    modifier raffleOpen() {
        if(block.timestamp >= _globalData.endTime) revert Errors.TIME_EXCEEDED();
        _;
    }
    modifier raffleEnded() {
        if(block.timestamp < _globalData.endTime) revert Errors.TIME_NOT_EXCEEDED();
        _;
    }

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

    function purchaseTicket(uint256 nbOfTickets) external override raffleOpen(){
        if(nbOfTickets == 0) revert Errors.CANT_BE_ZERO();
        if(_globalData.ticketSupply + nbOfTickets> _globalData.maxTicketSupply) revert Errors.MAX_TICKET_SUPPLY_EXCEEDED();
        if(_calculateTicketsCost(nbOfTickets) > _globalData.purchaseCurrency.balanceOf(msg.sender)) revert Errors.NOT_ENOUGH_BALANCE();
        
        _globalData.purchaseCurrency.transferFrom(msg.sender, address(this), _calculateTicketsCost(nbOfTickets));

        uint256[] storage ownerTickets = _ownerTickets[msg.sender];
        uint256 ticketNumber = _globalData.ticketSupply + 1 ;

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
        _globalData.ticketSupply = ticketNumber - 1;
        emit TicketPurchased(msg.sender, ticketsPurchased);
    }


    function totalSupply() public view returns(uint256) {
        return _globalData.ticketSupply;
    }

    function maxSupply() public view returns(uint256) {
        return _globalData.maxTicketSupply;
    }

    function creator() public view returns(address) {
        return _globalData.creator;
    }
    function purchaseCurrency() public view returns(IERC20) {
        return _globalData.purchaseCurrency;
    }

    function ticketPrice() public view returns(uint256) {
        return _globalData.ticketPrice;
    }

    function endTime() public view returns(uint64) {
        return _globalData.endTime;
    }
    
    function winningTicket() public raffleEnded() view returns(uint256) {
        return _globalData.winningTicketNumber;
    }
    
    function winerAddress() public raffleEnded() view returns(address) {
        return _ticketOwner[_globalData.winningTicketNumber];
    }

    function nftToWin() public view returns(IERC721 nftContractAddress, uint256 nftId) {
        return (_globalData.nftContract, _globalData.nftId);
    }

    function balanceOf(address owner) external view returns(uint256[] memory){
        return _ownerTickets[owner];
    }

    function ownerOf(uint256 id) external view returns(address){
        return _ticketOwner[id];
    }


    function _calculateTicketsCost(uint256 nbOfTickets) internal view returns(uint256 amountPrice) {
        amountPrice = _globalData.ticketPrice * nbOfTickets;
    }
}