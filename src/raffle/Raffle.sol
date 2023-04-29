// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {RaffleDataTypes} from "../libraries/types/RaffleDataTypes.sol";

import {IRaffle} from "../interfaces/IRaffle.sol";
import {IRandomProvider} from "../interfaces/IRandomProvider.sol";
import {INFTCollectionWhitelist} from "../interfaces/INFTCollectionWhitelist.sol";
import {ITokenWhitelist} from "../interfaces/ITokenWhitelist.sol";
import {IConfigManager} from "../interfaces/IConfigManager.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";

contract Raffle is IRaffle, Initializable {
    using PercentageMath for uint;

    //----------------------------------------
    // Storage
    //----------------------------------------

    // Mapping from ticket ID to owner address
    mapping(uint256 => address) internal _ticketOwner;

    // Mapping owner address to tickets list
    mapping(address => uint256[]) internal _ownerTickets;

    mapping(address => bool) internal _hasUserClaimedRefund;

    RaffleDataTypes.RaffleData internal _globalData;

    //----------------------------------------
    // Events
    //----------------------------------------

    event TicketPurchased(address indexed buyer, uint256[] ticketNumbers);
    event WinnerClaimedPrice(
        address indexed winner,
        address indexed nftContract,
        uint256 nftId
    );
    event CreatorClaimedTicketSalesAmount(
        address indexed winner,
        uint256 creatorAmountReceived,
        uint256 treasuryAmount
    );
    event WinningTicketDrawned(uint256 winningTicket);
    event CreatorExerciseInsurance(address creator);
    event UserClaimedRefundInvestment(address user, uint256 amountReceived);

    //----------------------------------------
    // Modifier
    //----------------------------------------

    modifier ticketSalesOpen() {
        if (block.timestamp >= endTicketSales()) revert Errors.RAFFLE_CLOSE();
        _;
    }

    modifier ticketSalesClose() {
        if (block.timestamp < endTicketSales())
            revert Errors.RAFFLE_STILL_OPEN();
        _;
    }

    modifier ticketHasNotBeDrawn() {
        if (
            raffleStatus() == RaffleDataTypes.RaffleStatus.WinningTicketsDrawned
        ) revert Errors.TICKET_ALREADY_DRAWN();
        _;
    }

    modifier ticketHasBeDrawn() {
        if (
            raffleStatus() != RaffleDataTypes.RaffleStatus.WinningTicketsDrawned
        ) revert Errors.TICKET_NOT_DRAWN();
        _;
    }

    modifier drawnRequested() {
        if (raffleStatus() != RaffleDataTypes.RaffleStatus.DrawnRequested)
            revert Errors.TICKET_DRAWN_NOT_REQUESTED();
        _;
    }

    modifier notRefundMode() {
        if (raffleStatus() == RaffleDataTypes.RaffleStatus.RefundMode)
            revert Errors.IN_REFUND_MODE();
        _;
    }

    modifier onlyRandomProviderContract() {
        if (randomProvider() != msg.sender)
            revert Errors.NOT_RANDOM_PROVIDER_CONTRACT();
        _;
    }

    modifier onlyCreator(){
        if (creator() != msg.sender)
            revert Errors.NOT_CREATOR();
        _;
    }

    //----------------------------------------
    // Initialize function
    //----------------------------------------
    function initialize(
        RaffleDataTypes.InitRaffleParams memory params
    ) external override payable initializer {
        _checkData(params);
        _globalData.isEthTokenSales = params.isEthTokenSales;
        _globalData.implementationManager = params.implementationManager;
        _globalData.creator = params.creator;
        if (!params.isEthTokenSales) {
            _globalData.purchaseCurrency = params.purchaseCurrency;
        }
        _globalData.nftContract = params.nftContract;
        _globalData.nftId = params.nftId;
        _globalData.maxTicketSupply = params.maxTicketSupply;
        _globalData.ticketPrice = params.ticketPrice;
        _globalData.minTicketSalesInsurance = params.minTicketSalesInsurance;
        _globalData.endTicketSales =
            uint64(block.timestamp) +
            params.ticketSaleDuration;
        _globalData.maxTicketAllowedToPurchase = params
            .maxTicketAllowedToPurchase;
    }

    //----------------------------------------
    // Externals Functions
    //----------------------------------------
    
    /// @inheritdoc IRaffle
    function purchaseTickets(
        uint256 nbOfTickets
    ) external override ticketSalesOpen {
        if (_globalData.isEthTokenSales) revert Errors.IS_ETH_RAFFLE();
        if (nbOfTickets == 0) revert Errors.CANT_BE_ZERO();
         if( _globalData.maxTicketAllowedToPurchase > 0 && balanceOf(msg.sender).length + nbOfTickets > _globalData.maxTicketAllowedToPurchase)
            revert Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE();
        if (totalSupply() + nbOfTickets > _globalData.maxTicketSupply)
            revert Errors.MAX_TICKET_SUPPLY_EXCEEDED();
        uint256 ticketCost =  _calculateTicketsCost(nbOfTickets);

        _globalData.purchaseCurrency.transferFrom(
            msg.sender,
            address(this),
            ticketCost
        );

        uint256[] memory ticketsPurchased = _purchaseTicket(nbOfTickets);

        emit TicketPurchased(msg.sender, ticketsPurchased);
    }

    /// @inheritdoc IRaffle
    function purchaseTicketsInEth(
        uint256 nbOfTickets
    ) external payable override ticketSalesOpen {
        if (!_globalData.isEthTokenSales) revert Errors.NOT_ETH_RAFFLE();
        if (nbOfTickets == 0) revert Errors.CANT_BE_ZERO();
        if( _globalData.maxTicketAllowedToPurchase > 0 && balanceOf(msg.sender).length + nbOfTickets > _globalData.maxTicketAllowedToPurchase)
            revert Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE();
        if (totalSupply() + nbOfTickets > _globalData.maxTicketSupply)
            revert Errors.MAX_TICKET_SUPPLY_EXCEEDED();
        if (_calculateTicketsCost(nbOfTickets) != msg.value)
            revert Errors.WRONG_MSG_VALUE();
        uint256[] memory ticketsPurchased = _purchaseTicket(nbOfTickets);
        emit TicketPurchased(msg.sender, ticketsPurchased);
    }

    /// @inheritdoc IRaffle
    function drawnTickets()
        external
        override
        ticketSalesClose
        ticketHasNotBeDrawn
        notRefundMode
    {
        if (_globalData.ticketSupply > 0 && _globalData.ticketSupply >= _globalData.minTicketSalesInsurance){
            _globalData.status = RaffleDataTypes.RaffleStatus.DrawnRequested;
            IRandomProvider(randomProvider()).requestRandomNumbers(1);
        } else {
            _globalData.status = RaffleDataTypes.RaffleStatus.RefundMode;
        }
    }

    /// @inheritdoc IRaffle
    function drawnTickets(
        uint256[] memory randomNumbers
    ) external override onlyRandomProviderContract drawnRequested {
        if (randomNumbers[0] == 0 || randomNumbers.length == 0) {
            _globalData.status = RaffleDataTypes.RaffleStatus.Init;
        } else {
            _globalData.winningTicketNumber =
                (randomNumbers[0] % _globalData.ticketSupply) +
                1;
            _globalData.status = RaffleDataTypes
                .RaffleStatus
                .WinningTicketsDrawned;
            emit WinningTicketDrawned(_globalData.winningTicketNumber);
        }
    }

    /// @inheritdoc IRaffle
    function claimTicketSalesAmount()
        external
        override
        ticketSalesClose
        ticketHasBeDrawn
        onlyCreator
    {
        if (_globalData.isEthTokenSales) revert Errors.IS_ETH_RAFFLE();
        uint256 insuranceCost = insurancePaid();
        uint256 totalBalance = _globalData.purchaseCurrency.balanceOf(
            address(this)
        );
        uint256 ticketSalesAmount = totalBalance - insuranceCost;
        (
            uint256 creatorAmount,
            uint256 treasuryFeesAmount
        ) = _calculateAmountToTransfer(ticketSalesAmount);
        uint256 totalClaimableAmount = insuranceCost + creatorAmount;
        _globalData.purchaseCurrency.transfer(
            _globalData.implementationManager.getImplementationAddress(
                ImplementationInterfaceNames.Treasury
            ),
            treasuryFeesAmount
        );
        _globalData.purchaseCurrency.transfer(msg.sender, totalClaimableAmount);
        emit CreatorClaimedTicketSalesAmount(
            msg.sender,
            totalClaimableAmount,
            treasuryFeesAmount
        );
    }

    /// @inheritdoc IRaffle
    function claimEthTicketSalesAmount()
        external
        override
        ticketSalesClose
        ticketHasBeDrawn
        onlyCreator
    {
        if (!_globalData.isEthTokenSales) revert Errors.NOT_ETH_RAFFLE();
        uint256 insuranceCost = insurancePaid();
        uint256 totalBalance = address(this).balance;
        uint256 ticketSalesAmount = totalBalance - insuranceCost;
        (
            uint256 creatorAmount,
            uint256 treasuryFeesAmount
        ) = _calculateAmountToTransfer(ticketSalesAmount);
        uint256 totalClaimableAmount = insuranceCost + creatorAmount;
        _safeTransferETH(
            _globalData.implementationManager.getImplementationAddress(
                ImplementationInterfaceNames.Treasury
            ),
            treasuryFeesAmount
        );
        _safeTransferETH(msg.sender, totalClaimableAmount);
        emit CreatorClaimedTicketSalesAmount(
            msg.sender,
            totalClaimableAmount,
            treasuryFeesAmount
        );
    }

    /// @inheritdoc IRaffle
    function winnerClaimPrice() external override ticketSalesClose ticketHasBeDrawn {
        if (msg.sender != winnerAddress())
            revert Errors.MSG_SENDER_NOT_WINNER();
        _globalData.nftContract.safeTransferFrom(
            address(this),
            msg.sender,
            _globalData.nftId
        );
        emit WinnerClaimedPrice(
            msg.sender,
            address(_globalData.nftContract),
            _globalData.nftId
        );
    }

    /// @inheritdoc IRaffle
    function userExerciseRefund()
        external
        override
        ticketSalesClose
        ticketHasNotBeDrawn
    {
        if (_globalData.isEthTokenSales) revert Errors.IS_ETH_RAFFLE();
        if (_globalData.ticketSupply >= _globalData.minTicketSalesInsurance)
            revert Errors.SALES_EXCEED_INSURANCE_LIMIT();
        if (_hasUserClaimedRefund[msg.sender]) revert Errors.ALREADY_CLAIMED();
        _hasUserClaimedRefund[msg.sender] = true;
        uint256 amountOfTicketPurchased = balanceOf(msg.sender).length;
        if (amountOfTicketPurchased == 0) revert Errors.NOTHING_TO_CLAIM();
        uint256 totalRefundAmount = _calculateTicketsCost(
            amountOfTicketPurchased
        ) + _calculateUserInsurancePart(amountOfTicketPurchased);
        _globalData.purchaseCurrency.transfer(
            msg.sender,
            totalRefundAmount
        );
        emit UserClaimedRefundInvestment(msg.sender, totalRefundAmount);
    }

    /// @inheritdoc IRaffle
    function userExerciseRefundInEth()
        external
        override
        ticketSalesClose
        ticketHasNotBeDrawn
    {
        if (!_globalData.isEthTokenSales) revert Errors.NOT_ETH_RAFFLE();
        if (_globalData.ticketSupply >= _globalData.minTicketSalesInsurance)
            revert Errors.SALES_EXCEED_INSURANCE_LIMIT();
        if (_hasUserClaimedRefund[msg.sender]) revert Errors.ALREADY_CLAIMED();
        _hasUserClaimedRefund[msg.sender] = true;
        uint256 amountOfTicketPurchased = balanceOf(msg.sender).length;
        if (amountOfTicketPurchased == 0) revert Errors.NOTHING_TO_CLAIM();
        uint256 totalRefundAmount = _calculateTicketsCost(
            amountOfTicketPurchased
        ) + _calculateUserInsurancePart(amountOfTicketPurchased);
        _safeTransferETH(msg.sender, totalRefundAmount);       
        emit UserClaimedRefundInvestment(msg.sender, totalRefundAmount);
    }

    /// @inheritdoc IRaffle
    function creatorExerciseRefund()
        external
        override
        ticketSalesClose
        ticketHasNotBeDrawn
        onlyCreator
    {
        if (_globalData.isEthTokenSales) revert Errors.IS_ETH_RAFFLE();
        if(_globalData.ticketSupply > 0){
            if (_globalData.ticketSupply >= _globalData.minTicketSalesInsurance)
                revert Errors.SALES_EXCEED_INSURANCE_LIMIT();
            if (raffleStatus() != RaffleDataTypes.RaffleStatus.RefundMode) {
                _globalData.status = RaffleDataTypes.RaffleStatus.RefundMode;
            }
        }
        if(_globalData.minTicketSalesInsurance > 0){
            (uint256 treasuryFeesAmount, ) = _calculateInsuranceSplit();
            address treasuryAddress = _globalData
                .implementationManager
                .getImplementationAddress(ImplementationInterfaceNames.Treasury);
            _globalData.purchaseCurrency.transfer(
                treasuryAddress,
                treasuryFeesAmount
            );

            if(_globalData.ticketSupply == 0) {
                _globalData.purchaseCurrency.transfer(
                    creator(),
                    insurancePaid() - treasuryFeesAmount
                );
            }
        }

        _globalData.nftContract.safeTransferFrom(
            address(this),
            creator(),
            _globalData.nftId
        );
        emit CreatorExerciseInsurance(creator());
    }
      
    /// @inheritdoc IRaffle
    function creatorExerciseRefundInEth()
        external
        override
        ticketSalesClose
        ticketHasNotBeDrawn
        onlyCreator
    {
        if (!_globalData.isEthTokenSales) revert Errors.NOT_ETH_RAFFLE();  
        if(_globalData.ticketSupply > 0){
            if (_globalData.ticketSupply >= _globalData.minTicketSalesInsurance)
                revert Errors.SALES_EXCEED_INSURANCE_LIMIT();
            if (raffleStatus() != RaffleDataTypes.RaffleStatus.RefundMode) {
                _globalData.status = RaffleDataTypes.RaffleStatus.RefundMode;
            }
        }
        if(_globalData.minTicketSalesInsurance > 0){
            (uint256 treasuryFeesAmount, ) = _calculateInsuranceSplit();
            address treasuryAddress = _globalData
                .implementationManager
                .getImplementationAddress(ImplementationInterfaceNames.Treasury);
            _safeTransferETH(treasuryAddress, treasuryFeesAmount);

            if(_globalData.ticketSupply == 0) {
                _safeTransferETH(
                    creator(),
                    insurancePaid() - treasuryFeesAmount
                );
            }
        }
        _globalData.nftContract.safeTransferFrom(
            address(this),
            creator(),
            _globalData.nftId
        );
        emit CreatorExerciseInsurance(creator());
    }

    /// @inheritdoc IRaffle
    function totalSupply() public view override returns (uint256) {
        return _globalData.ticketSupply;
    }

    /// @inheritdoc IRaffle
    function maxSupply() public view override returns (uint256) {
        return _globalData.maxTicketSupply;
    }

    /// @inheritdoc IRaffle
    function creator() public view override returns (address) {
        return _globalData.creator;
    }

    /// @inheritdoc IRaffle
    function purchaseCurrency() public view override returns (IERC20) {
        return _globalData.purchaseCurrency;
    }

    /// @inheritdoc IRaffle
    function ticketPrice() public view override returns (uint256) {
        return _globalData.ticketPrice;
    }

    /// @inheritdoc IRaffle
    function endTicketSales() public view override returns (uint64) {
        return _globalData.endTicketSales;
    }

    /// @inheritdoc IRaffle
    function winningTicket()
        public
        view
        override
        ticketSalesClose
        ticketHasBeDrawn
        returns (uint256)
    {
        return _globalData.winningTicketNumber;
    }

    /// @inheritdoc IRaffle
    function winnerAddress()
        public
        view
        override
        ticketSalesClose
        ticketHasBeDrawn
        returns (address)
    {
        return _ticketOwner[_globalData.winningTicketNumber];
    }

    /// @inheritdoc IRaffle
    function nftToWin()
        public
        view
        override
        returns (IERC721 nftContractAddress, uint256 nftId)
    {
        return (_globalData.nftContract, _globalData.nftId);
    }

    /// @inheritdoc IRaffle
    function raffleStatus()
        public
        view
        override
        returns (RaffleDataTypes.RaffleStatus)
    {
        return _globalData.status;
    }

    /// @inheritdoc IRaffle
    function balanceOf(
        address user
    ) public view override returns (uint256[] memory) {
        return _ownerTickets[user];
    }

    /// @inheritdoc IRaffle
    function ownerOf(uint256 id) public view override returns (address) {
        return _ticketOwner[id];
    }

    /// @inheritdoc IRaffle
    function randomProvider() public view override returns (address) {
        return
            _globalData.implementationManager.getImplementationAddress(
                ImplementationInterfaceNames.RandomProvider
            );
    }

    /// @inheritdoc IRaffle
    function isEthTokenSales() public view override returns (bool) {
        return _globalData.isEthTokenSales;
    }

    function insurancePaid() public view returns (uint256) {
        if (_globalData.minTicketSalesInsurance == 0) return 0;
        IConfigManager configManager = IConfigManager(
            _globalData.implementationManager.getImplementationAddress(
                ImplementationInterfaceNames.ConfigManager
            )
        );
        return
            _calculateInsuranceCost(
                _globalData.minTicketSalesInsurance,
                _globalData.ticketPrice,
                configManager.insuranceSalesPercentage()
            );
    }

    //----------------------------------------
    // Internals Functions
    //----------------------------------------

    /**
     * @notice check that initialize data are correct
     * @param params the struct data use for initialization
     */
    function _checkData(
        RaffleDataTypes.InitRaffleParams memory params
    ) internal {
        if (address(params.implementationManager) == address(0))
            revert Errors.NOT_ADDRESS_0();
        if (!params.isEthTokenSales) {
            if (!_getTokenWhitelist(params.implementationManager).isWhitelisted(
                    address(params.purchaseCurrency)))
                revert Errors.TOKEN_NOT_WHITELISTED();
        }
        address nftWhitelist = params
            .implementationManager
            .getImplementationAddress(
                ImplementationInterfaceNames.NFTWhitelist
            );
        if (
            !INFTCollectionWhitelist(nftWhitelist).isWhitelisted(
                address(params.nftContract)
            )
        ) revert Errors.COLLECTION_NOT_WHITELISTED();
        if (params.ticketPrice == 0) revert Errors.CANT_BE_ZERO();
        if (params.maxTicketSupply == 0) revert Errors.CANT_BE_ZERO();
        IConfigManager configManager = IConfigManager(
            params.implementationManager.getImplementationAddress(
                ImplementationInterfaceNames.ConfigManager
            )
        );
        if (params.maxTicketSupply > configManager.maxTicketSupplyAllowed())
            revert Errors.EXCEED_MAX_VALUE_ALLOWED();
        (uint256 minDuration, uint256 maxDuration) = configManager
            .ticketSalesDurationLimits();
        uint256 ticketSaleDuration = params.ticketSaleDuration;
        if (
            ticketSaleDuration < minDuration || ticketSaleDuration > maxDuration
        ) revert Errors.OUT_OF_RANGE();
        if (params.minTicketSalesInsurance > 0) {
            uint256 insuranceCost = _calculateInsuranceCost(
                params.minTicketSalesInsurance,
                params.ticketPrice,
                configManager.insuranceSalesPercentage()
            );
            if (params.isEthTokenSales) {
                if (params.isEthTokenSales && msg.value != insuranceCost)
                    revert Errors.INSURANCE_AMOUNT();
            } else {
                if(params.purchaseCurrency.balanceOf(address(this)) != insuranceCost)
                    revert Errors.INSURANCE_AMOUNT();
            }
        }
    }

    /**
     * @notice calculate the total price that must be paid regarding the amount of tickets to buy
     * @return amountPrice the total cost
     */
    function _calculateTicketsCost(
        uint256 nbOfTickets
    ) internal view returns (uint256 amountPrice) {
        amountPrice = _globalData.ticketPrice * nbOfTickets;
    }

    /**
     * @notice calculate the amount in insurance creator paid
     * @param minTicketSalesInsurance is the amount of ticket cover by the insurance
     * @param ticketCost is the price of one ticket
     * @param insurancePercentage is the percentage that the creator has to pay as insurance
     * @return insuranceAmount the total cost
     */
    function _calculateInsuranceCost(
        uint256 minTicketSalesInsurance,
        uint256 ticketCost,
        uint256 insurancePercentage
    ) internal pure returns (uint256 insuranceAmount) {
        insuranceAmount = (minTicketSalesInsurance * ticketCost).percentMul(
            insurancePercentage
        );
    }

    /**
     * @notice attribute ticket to msg.sender
     * @param nbOfTickets the amount of ticket that the msg.sender to purchasing
     * @return ticketsPurchased the list of tickets purchased by the msg.sender
     */
    function _purchaseTicket(
        uint256 nbOfTickets
    ) internal returns (uint256[] memory ticketsPurchased) {
        uint256[] storage ownerTickets = _ownerTickets[msg.sender];
        uint256 ticketNumber = _globalData.ticketSupply;

        ticketsPurchased = new uint256[](nbOfTickets);
        for (uint i; i < nbOfTickets; ) {
            ++ticketNumber;
            ticketsPurchased[i] = ticketNumber;
            ownerTickets.push(ticketNumber);
            _ticketOwner[ticketNumber] = msg.sender;
            unchecked {
                ++i;
            }
        }
        _globalData.ticketSupply = ticketNumber;
    }

    function _calculateAmountToTransfer(
        uint256 ticketSalesAmount
    )
        internal
        view
        returns (uint256 creatorAmount, uint256 treasuryFeesAmount)
    {
        IConfigManager configManager = IConfigManager(
            _globalData.implementationManager.getImplementationAddress(
                ImplementationInterfaceNames.ConfigManager
            )
        );
        treasuryFeesAmount = ticketSalesAmount.percentMul(
            configManager.protocolFeesPercentage()
        );
        creatorAmount = ticketSalesAmount - treasuryFeesAmount;
    }

    function _calculateUserInsurancePart(
        uint256 nbOfTicketPurchased
    ) internal view returns (uint256 userAmountToReceive) {
        (, uint256 amountPerTicket) = _calculateInsuranceSplit();
        userAmountToReceive = amountPerTicket * nbOfTicketPurchased;
    }

    function _calculateInsuranceSplit()
        internal
        view
        returns (uint256 treasuryAmount, uint256 insurancePartPerTicket)
    {
        IConfigManager configManager = IConfigManager(
            _globalData.implementationManager.getImplementationAddress(
                ImplementationInterfaceNames.ConfigManager
            )
        );

        uint256 insuranceCost = _calculateInsuranceCost(
            _globalData.minTicketSalesInsurance,
            _globalData.ticketPrice,
            configManager.insuranceSalesPercentage()
        );

        treasuryAmount = insuranceCost.percentMul(configManager.protocolFeesPercentage());
        if(_globalData.ticketSupply == 0) {
            return(treasuryAmount, 0);
        }

        insurancePartPerTicket = (insuranceCost - treasuryAmount) / _globalData.ticketSupply;
        //Avoid dust
        treasuryAmount =
            insuranceCost -
            insurancePartPerTicket *
            _globalData.ticketSupply;
    }

    /**
     * @notice Transfers ETH to the recipient address
     * @param to The destination of the transfer
     * @param value The value to be transferred
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = payable(to).call{value: value}(new bytes(0));
        if (!success) revert Errors.TRANSFER_FAIL();
    }

    function _getTokenWhitelist(IImplementationManager _implementationManager) internal view returns(ITokenWhitelist){
        address tokenWhitelist = _implementationManager.getImplementationAddress(ImplementationInterfaceNames.TokenWhitelist);
        return ITokenWhitelist(tokenWhitelist);
    }
}
