// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";

import {IRaffle} from "../interfaces/IRaffle.sol";
import {IRandomProvider} from "../interfaces/IRandomProvider.sol";
import {INFTCollectionWhitelist} from "../interfaces/INFTCollectionWhitelist.sol";
import {IConfigManager} from "../interfaces/IConfigManager.sol";

import {RaffleDataTypes} from "./RaffleDataTypes.sol";

 
contract Raffle is IRaffle, Initializable {

    using PercentageMath for uint;

    //----------------------------------------
    // Storage
    //----------------------------------------

    // Mapping from ticket ID to owner address
    mapping(uint256 => address) internal _ticketOwner;

    // Mapping owner address to tickets list
    mapping(address => uint256[]) internal _ownerTickets;

    RaffleDataTypes.RaffleData internal _globalData;


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
        if(block.timestamp >= endTicketSales()) revert Errors.RAFFLE_CLOSE();
        _;
    }
    
    modifier ticketSalesClose() {
        if(block.timestamp < endTicketSales()) revert Errors.RAFFLE_STILL_OPEN();
        _;
    }

    modifier ticketHasNotBeDrawn(){
        if(raffleStatus() == RaffleDataTypes.RaffleStatus.WinningTicketsDrawned) revert Errors.TICKET_ALREADY_DRAWN();
        _;
    }

    modifier ticketHasBeDrawn(){
        if(raffleStatus() != RaffleDataTypes.RaffleStatus.WinningTicketsDrawned) revert Errors.TICKET_NOT_DRAWN();
        _;
    }

    modifier drawnRequested(){
        if(raffleStatus() != RaffleDataTypes.RaffleStatus.DrawnRequested) revert Errors.TICKET_DRAWN_NOT_REQUESTED();
        _;
    }
    
    modifier onlyRandomProviderContract(){
        if(randomProvider() != msg.sender) revert Errors.NOT_RANDOM_PROVIDER_CONTRACT();
        _;
    }

    //----------------------------------------
    // Initialize function
    //----------------------------------------
    function initialize(RaffleDataTypes.InitRaffleParams memory params) external override initializer {
        _checkData(params);
        _globalData.implementationManager = params.implementationManager;
        _globalData.creator = params.creator;
        _globalData.purchaseCurrency = params.purchaseCurrency;
        _globalData.nftContract = params.nftContract;
        _globalData.nftId = params.nftId;
        _globalData.maxTicketSupply = params.maxTicketSupply;
        _globalData.ticketPrice = params.ticketPrice;
        _globalData.endTicketSales = uint64(block.timestamp) + params.ticketSaleDuration;
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
    function drawnTickets() external override ticketSalesClose() ticketHasNotBeDrawn() {
        _globalData.status = RaffleDataTypes.RaffleStatus.DrawnRequested;
        IRandomProvider(randomProvider()).requestRandomNumbers(1);
    }

    /// @inheritdoc IRaffle
    function drawnTickets(uint256[] memory randomNumbers) external override onlyRandomProviderContract() drawnRequested() {
        if( randomNumbers[0] == 0 && randomNumbers.length == 0){
            _globalData.status = RaffleDataTypes.RaffleStatus.Init;
        }
        _globalData.winningTicketNumber = (randomNumbers[0] % _globalData.ticketSupply) + 1;
        _globalData.status = RaffleDataTypes.RaffleStatus.WinningTicketsDrawned;
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
        IConfigManager configManager = IConfigManager(_globalData.implementationManager.getImplementationAddress(ImplementationInterfaceNames.ConfigManager));
        uint256 ticketSalesAmount = _globalData.purchaseCurrency.balanceOf(address(this));
        uint256 treasuryFeesAmount = ticketSalesAmount.percentMul(configManager.procolFeesPercentage());
        uint256 creatorAmount = ticketSalesAmount-treasuryFeesAmount;
        _globalData.purchaseCurrency.transfer(_globalData.implementationManager.getImplementationAddress(ImplementationInterfaceNames.Treasury), treasuryFeesAmount);
        _globalData.purchaseCurrency.transfer(msg.sender, creatorAmount);
        emit CreatorClaimTicketSalesAmount(address(this), msg.sender, creatorAmount);
    }

    /// @inheritdoc IRaffle
    function totalSupply() public override view returns(uint256) {
        return _globalData.ticketSupply;
    }

   /// @inheritdoc IRaffle
    function maxSupply() public override view returns(uint256) {
        return _globalData.maxTicketSupply;
    }

    /// @inheritdoc IRaffle
    function creator() public override view returns(address) {
        return _globalData.creator;
    }

   /// @inheritdoc IRaffle
    function purchaseCurrency() public override view returns(IERC20) {
        return _globalData.purchaseCurrency;
    }

    /// @inheritdoc IRaffle
    function ticketPrice() public override view returns(uint256) {
        return _globalData.ticketPrice;
    }

   /// @inheritdoc IRaffle
    function endTicketSales() public override view returns(uint64) {
        return _globalData.endTicketSales;
    }

    /// @inheritdoc IRaffle
    function winningTicket() public override view ticketSalesClose() ticketHasBeDrawn() returns(uint256) {
        return _globalData.winningTicketNumber;
    }
    
    /// @inheritdoc IRaffle
    function winnerAddress() public override view ticketSalesClose() ticketHasBeDrawn() returns(address) {
        return _ticketOwner[_globalData.winningTicketNumber];
    }

    /// @inheritdoc IRaffle
    function nftToWin() public override view returns(IERC721 nftContractAddress, uint256 nftId) {
        return (_globalData.nftContract, _globalData.nftId);
    }

    /// @inheritdoc IRaffle
    function raffleStatus() public override view returns(RaffleDataTypes.RaffleStatus){
        return  _globalData.status;
    }

    /// @inheritdoc IRaffle
    function balanceOf(address user) public override view returns(uint256[] memory){
        return _ownerTickets[user];
    }

    /// @inheritdoc IRaffle
    function ownerOf(uint256 id) public override view returns(address){
        return _ticketOwner[id];
    }

    /// @inheritdoc IRaffle
    function randomProvider() public override view returns(address){
        return _globalData.implementationManager.getImplementationAddress(ImplementationInterfaceNames.RandomProvider);
    }

    //----------------------------------------
    // Internals Functions
    //----------------------------------------
    
    /**
    * @notice check that initialize data are correct
    * @param params the struct data use for initialization
    */
    function _checkData(RaffleDataTypes.InitRaffleParams memory params) internal view {
        if(address(params.implementationManager) == address(0)) revert Errors.NOT_ADDRESS_0();
        if(address(params.purchaseCurrency) == address(0)) revert Errors.NOT_ADDRESS_0();
        address nftWhitelist = params.implementationManager.getImplementationAddress(ImplementationInterfaceNames.NFTWhitelist);
        if(!INFTCollectionWhitelist(nftWhitelist).isWhitelisted(address(params.nftContract))) revert Errors.COLLECTION_NOT_WHITELISTED();
        if(params.nftContract.ownerOf(params.nftId) != address(this)) revert Errors.NOT_NFT_OWNER();
        if(params.ticketPrice == 0) revert Errors.CANT_BE_ZERO();
        if(params.maxTicketSupply == 0) revert Errors.CANT_BE_ZERO();
        IConfigManager configManager = IConfigManager(params.implementationManager.getImplementationAddress(ImplementationInterfaceNames.ConfigManager));
        if(params.maxTicketSupply > configManager.maxTicketSupplyAllowed()) revert Errors.EXCEED_MAX_VALUE_ALLOWED();
        (uint256 minDuration, uint256 maxDuration) = configManager.ticketSalesDurationLimits();
        uint256 ticketSaleDuration = params.ticketSaleDuration;
        if(ticketSaleDuration < minDuration || ticketSaleDuration > maxDuration) revert Errors.OUT_OF_RANGE();
    }

    /**
    * @notice calculate the total price that must be paid regarding the amount of tickets to buy
    * @return amountPrice the total cost
    */
    function _calculateTotalTicketsPrice(uint256 nbOfTickets) internal view returns(uint256 amountPrice) {
        amountPrice = _globalData.ticketPrice * nbOfTickets;
    }
}