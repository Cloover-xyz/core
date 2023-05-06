// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {console2} from 'forge-std/console2.sol';

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {ClooverRaffleDataTypes} from "../libraries/types/ClooverRaffleDataTypes.sol";

import {IClooverRaffle} from "../interfaces/IClooverRaffle.sol";
import {IClooverRaffleFactory} from "../interfaces/IClooverRaffleFactory.sol";
import {IRandomProvider} from "../interfaces/IRandomProvider.sol";
import {INFTCollectionWhitelist} from "../interfaces/INFTCollectionWhitelist.sol";
import {ITokenWhitelist} from "../interfaces/ITokenWhitelist.sol";
import {IConfigManager} from "../interfaces/IConfigManager.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";

contract ClooverRaffle is IClooverRaffle, Initializable {
    using PercentageMath for uint;

    //----------------------------------------
    // Storage
    //----------------------------------------

    ClooverRaffleDataTypes.PurchasedEntries[] internal purchasedEntries;

    // Mapping owner address to PurchasedEntries index
    mapping(address => ClooverRaffleDataTypes.ParticipantInfo) internal participantInfoMap;

    ClooverRaffleDataTypes.ConfigData internal config;

    ClooverRaffleDataTypes.LifeCycleData internal lifeCycleData;

    //----------------------------------------
    // Events
    //----------------------------------------

    event TicketPurchased(address indexed buyer, uint16 firstTicket, uint16 nbOfTicketsPurchased);
    event WinnerClaimed(address winner);
    event CreatorClaimed(
        address indexed winner,
        uint256 creatorAmountReceived,
        uint256 protocolFeeAmount,
        uint256 royaltiesAmount
    );
    event WinningTicketDrawn(uint16 winningTicket);
    event CreatorClaimedInsurance(address creator);
    event UserClaimedRefund(address indexed user, uint256 amountReceived);
    event RaffleCancelled(address creator);
    event RaffleStatus(ClooverRaffleDataTypes.RaffleStatus indexed status);

    //----------------------------------------
    // Modifier
    //----------------------------------------

    modifier ticketSalesOpen() {
        if (block.timestamp >= endTicketSales()) revert Errors.RAFFLE_CLOSE();
        _;
    }

    modifier ticketSalesOver() {
        if (block.timestamp < endTicketSales())
            revert Errors.RAFFLE_STILL_OPEN();
        _;
    }

    modifier ticketHasNotBeDrawn() {
        if (
            raffleStatus() == ClooverRaffleDataTypes.RaffleStatus.DRAWN
        ) revert Errors.TICKET_ALREADY_DRAWN();
        _;
    }

    modifier winningTicketDrawn() {
        if (
            raffleStatus() != ClooverRaffleDataTypes.RaffleStatus.DRAWN
        ) revert Errors.TICKET_NOT_DRAWN();
        _;
    }

    modifier notRefundMode() {
        if (raffleStatus() == ClooverRaffleDataTypes.RaffleStatus.INSURANCE)
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
        ClooverRaffleDataTypes.InitializeRaffleParams memory params
    ) external override payable initializer {

        (uint16 _insuranceRate, uint16 _protocolFeeRate, bool _isEthRaffle) =_checkData(params);
        
        
        config = ClooverRaffleDataTypes.ConfigData({
            creator: params.creator,
            implementationManager: params.implementationManager,
            purchaseCurrency: params.purchaseCurrency,
            nftContract: params.nftContract,
            nftId: params.nftId,
            ticketPrice: params.ticketPrice,
            endTicketSales: uint64(block.timestamp) + params.ticketSalesDuration,
            maxTotalSupply: params.maxTotalSupply,
            ticketSalesInsurance: params.ticketSalesInsurance,
            maxTicketAllowedToPurchase: params.maxTicketAllowedToPurchase,
            protocolFeeRate: _protocolFeeRate,
            insuranceRate: _insuranceRate,
            royaltiesRate: params.royaltiesRate,
            isEthRaffle: _isEthRaffle
        });
    }

    //----------------------------------------
    // Externals Functions
    //----------------------------------------
    
    /// @inheritdoc IClooverRaffle
    function purchaseTickets(
        uint16 nbOfTickets
    ) external override ticketSalesOpen {
        _purchaseTicketInToken(nbOfTickets);
    }

    /// @inheritdoc IClooverRaffle
    function purchaseTicketsWithPermit(
        uint16 nbOfTickets,
        ClooverRaffleDataTypes.PermitData calldata permitData
    ) external override ticketSalesOpen {
         IERC20Permit(address(config.purchaseCurrency)).permit(
            msg.sender,
            address(this),
            permitData.amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        _purchaseTicketInToken(nbOfTickets);
    }

    /// @inheritdoc IClooverRaffle
    function purchaseTicketsInEth(
        uint16 nbOfTickets
    ) external payable override ticketSalesOpen {
        if (!isEthRaffle()) revert Errors.NOT_ETH_RAFFLE();
        if (nbOfTickets == 0) revert Errors.CANT_BE_ZERO();
        
        uint16 _maxTicketAllowedToPurchase = config.maxTicketAllowedToPurchase;
        if(_maxTicketAllowedToPurchase > 0 && participantInfoMap[msg.sender].nbOfTicketsPurchased + nbOfTickets > _maxTicketAllowedToPurchase)
            revert Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE();
        
        uint16 _currentSupply = currentSupply();
        if (_currentSupply + nbOfTickets > maxTotalSupply())
            revert Errors.TICKET_SUPPLY_OVERFLOW();
            
        if (_calculateTicketsCost(nbOfTickets) != msg.value)
            revert Errors.WRONG_MSG_VALUE();

        _purchaseTicket(nbOfTickets);

        emit TicketPurchased(msg.sender, _currentSupply, uint16(nbOfTickets));
    }

    /// @inheritdoc IClooverRaffle
    function draw()
        external
        override
        ticketSalesOver
        ticketHasNotBeDrawn
    {
        uint16 _currentSupply = currentSupply();
        if (_currentSupply > 0 && _currentSupply >= config.ticketSalesInsurance){
            lifeCycleData.status = ClooverRaffleDataTypes.RaffleStatus.DRAWNING;
            IRandomProvider(randomProvider()).requestRandomNumbers(1);
        } else {
            lifeCycleData.status = ClooverRaffleDataTypes.RaffleStatus.INSURANCE;
        }
        emit RaffleStatus(lifeCycleData.status);
    }

    /// @inheritdoc IClooverRaffle
    function draw(
        uint256[] memory randomNumbers
    ) external override onlyRandomProviderContract {
        if (randomNumbers[0] == 0) {
            lifeCycleData.status = ClooverRaffleDataTypes.RaffleStatus.DEFAULT;
        } else {
            uint16 winningTicketNumber = uint16((randomNumbers[0] % lifeCycleData.currentSupply) + 1);
            lifeCycleData.winningTicketNumber = winningTicketNumber;
            lifeCycleData.status = ClooverRaffleDataTypes.RaffleStatus.DRAWN;
            emit WinningTicketDrawn(winningTicketNumber);
        }
        emit RaffleStatus(lifeCycleData.status);
    }

    /// @inheritdoc IClooverRaffle
    function creatorClaimTicketSales()
        external
        override
        winningTicketDrawn
        onlyCreator
    {
        if (isEthRaffle()) revert Errors.IS_ETH_RAFFLE();
        IERC20 _purchaseCurrency = config.purchaseCurrency;
        IImplementationManager _implementationManager = config.implementationManager;
        
        uint256 insuranceCost = insurancePaid();
        uint256 totalBalance = _purchaseCurrency.balanceOf(address(this));
        uint256 ticketSalesAmount = totalBalance - insuranceCost;
        
        (
            uint256 creatorAmount,
            uint256 protocolFees,
            uint256 royaltiesAmount
        ) = _calculateAmountToTransfer(ticketSalesAmount);
        
        _purchaseCurrency.transfer(
            _implementationManager.getImplementationAddress(
                ImplementationInterfaceNames.Treasury
            ),
            protocolFees
        );
        
        if(royaltiesAmount > 0){
            _purchaseCurrency.transfer(
                INFTCollectionWhitelist(
                    _implementationManager.getImplementationAddress(
                        ImplementationInterfaceNames.NFTWhitelist
                    )
                ).getCollectionCreator(address(config.nftContract)),
                royaltiesAmount
            );
        }
        
        uint256 totalClaimableAmount = insuranceCost + creatorAmount;
        _purchaseCurrency.transfer(msg.sender, totalClaimableAmount);
        
        emit CreatorClaimed(
            msg.sender,
            totalClaimableAmount,
            protocolFees,
            royaltiesAmount
        );
    }

    /// @inheritdoc IClooverRaffle
    function creatorClaimTicketSalesInEth()
        external
        override
        winningTicketDrawn
        onlyCreator
    {
        if (!isEthRaffle()) revert Errors.NOT_ETH_RAFFLE();
        IImplementationManager _implementationManager = config.implementationManager;
        
        uint256 insuranceCost = insurancePaid();
        uint256 totalBalance = address(this).balance;
        uint256 ticketSalesAmount = totalBalance - insuranceCost;
        
        (
            uint256 creatorAmount,
            uint256 protocolFees,
            uint256 royaltiesAmount
        ) = _calculateAmountToTransfer(ticketSalesAmount);

        _safeTransferETH(
            _implementationManager.getImplementationAddress(
                ImplementationInterfaceNames.Treasury
            ),
            protocolFees
        );

        if(royaltiesAmount > 0){
            _safeTransferETH(
                INFTCollectionWhitelist(
                   _implementationManager.getImplementationAddress(
                        ImplementationInterfaceNames.NFTWhitelist
                    )
                ).getCollectionCreator(address(config.nftContract)),
                royaltiesAmount
            );
        }
        
        uint256 totalClaimableAmount = insuranceCost + creatorAmount;
        _safeTransferETH(msg.sender, totalClaimableAmount);
        
        emit CreatorClaimed(
            msg.sender,
            totalClaimableAmount,
            protocolFees,
            royaltiesAmount
        );
    }

    /// @inheritdoc IClooverRaffle
    function winnerClaim() external override winningTicketDrawn {
        if (msg.sender != winnerAddress())
            revert Errors.MSG_SENDER_NOT_WINNER();
        config.nftContract.safeTransferFrom(
            address(this),
            msg.sender,
            config.nftId
        );
        emit WinnerClaimed(msg.sender);
    }

    /// @inheritdoc IClooverRaffle
    function userClaimRefund()
        external
        override
        ticketSalesOver
        ticketHasNotBeDrawn
    {
        if (isEthRaffle()) revert Errors.IS_ETH_RAFFLE();

        uint256 totalRefundAmount = _calculateUserRefundAmount();

        config.purchaseCurrency.transfer(msg.sender, totalRefundAmount);

        emit UserClaimedRefund(msg.sender, totalRefundAmount);
    }

    /// @inheritdoc IClooverRaffle
    function userClaimRefundInEth()
        external
        override
        ticketSalesOver
        ticketHasNotBeDrawn
    {
        if (!isEthRaffle()) revert Errors.NOT_ETH_RAFFLE();
        
        uint256 totalRefundAmount = _calculateUserRefundAmount();

        _safeTransferETH(msg.sender, totalRefundAmount);       
        
        emit UserClaimedRefund(msg.sender, totalRefundAmount);
    }

    /// @inheritdoc IClooverRaffle
    function creatorClaimInsurance()
        external
        override
        ticketSalesOver
        ticketHasNotBeDrawn
        onlyCreator
    {
        if (isEthRaffle()) revert Errors.IS_ETH_RAFFLE();
        uint16 _ticketSalesInsurance = config.ticketSalesInsurance;  
        if(_ticketSalesInsurance == 0) revert Errors.NO_INSURANCE_TAKEN();
        uint16 _currentSupply = currentSupply();
        if(_currentSupply == 0) revert Errors.NOTHING_TO_CLAIM();
        
        if (_currentSupply >= _ticketSalesInsurance)
            revert Errors.SALES_EXCEED_INSURANCE_LIMIT();
        
        lifeCycleData.status = ClooverRaffleDataTypes.RaffleStatus.INSURANCE;
        
        (uint256 protocolFees, ) = _calculateInsuranceSplit();
        address treasuryAddress = config
            .implementationManager
            .getImplementationAddress(ImplementationInterfaceNames.Treasury);
        config.purchaseCurrency.transfer(
            treasuryAddress,
            protocolFees
        );

        config.nftContract.safeTransferFrom(
            address(this),
            creator(),
            config.nftId
        );
        emit CreatorClaimedInsurance(msg.sender);
    }
      
    /// @inheritdoc IClooverRaffle
    function creatorClaimInsuranceInEth()
        external
        override
        ticketSalesOver
        ticketHasNotBeDrawn
        onlyCreator
    {
        if (!isEthRaffle()) revert Errors.NOT_ETH_RAFFLE();
        uint16 _ticketSalesInsurance = config.ticketSalesInsurance;  
        if(_ticketSalesInsurance == 0) revert Errors.NO_INSURANCE_TAKEN();
        uint16 _currentSupply = currentSupply();
        if(_currentSupply == 0) revert Errors.NOTHING_TO_CLAIM();
        
        if (_currentSupply >= _ticketSalesInsurance)
            revert Errors.SALES_EXCEED_INSURANCE_LIMIT();
        
        lifeCycleData.status = ClooverRaffleDataTypes.RaffleStatus.INSURANCE;
                
        (uint256 protocolFees, ) = _calculateInsuranceSplit();
        address treasuryAddress = config
            .implementationManager
            .getImplementationAddress(ImplementationInterfaceNames.Treasury);
        _safeTransferETH(treasuryAddress, protocolFees);

        config.nftContract.safeTransferFrom(
            address(this),
            creator(),
            config.nftId
        );
        emit CreatorClaimedInsurance(msg.sender);
    }

    /// @inheritdoc IClooverRaffle
    function cancelRaffle() external override onlyCreator {
        if(currentSupply() > 0) revert Errors.SALES_ALREADY_STARTED();

        IClooverRaffleFactory(
            config.implementationManager.getImplementationAddress(
                ImplementationInterfaceNames.ClooverRaffleFactory
            )
        ).deregisterClooverRaffle();
            
        if(config.ticketSalesInsurance > 0){
            if(isEthRaffle()) {
                _safeTransferETH(
                    creator(),
                    insurancePaid()
                );
            } else {
                config.purchaseCurrency.transfer(
                    creator(),
                    insurancePaid()
                );
            }
        }
        
        config.nftContract.safeTransferFrom(
            address(this),
            creator(),
            config.nftId
        );
        emit RaffleCancelled(msg.sender);
        emit RaffleStatus(lifeCycleData.status);
    }

    /// @inheritdoc IClooverRaffle
    function maxTotalSupply() public view override returns (uint16) {
        return config.maxTotalSupply;
    }

    /// @inheritdoc IClooverRaffle
    function currentSupply() public view override returns (uint16) {
        return lifeCycleData.currentSupply;
    }

    /// @inheritdoc IClooverRaffle
    function creator() public view override returns (address) {
        return config.creator;
    }

    /// @inheritdoc IClooverRaffle
    function purchaseCurrency() public view override returns (IERC20) {
        return config.purchaseCurrency;
    }

    /// @inheritdoc IClooverRaffle
    function ticketPrice() public view override returns (uint256) {
        return config.ticketPrice;
    }

    /// @inheritdoc IClooverRaffle
    function endTicketSales() public view override returns (uint64) {
        return config.endTicketSales;
    }

    /// @inheritdoc IClooverRaffle
    function winningTicket()
        public
        view
        override
        winningTicketDrawn
        returns (uint16)
    {
        return lifeCycleData.winningTicketNumber;
    }

    /// @inheritdoc IClooverRaffle
    function winnerAddress()
        public
        view
        override
        ticketSalesOver
        returns (address)
    {
        if (lifeCycleData.winningTicketNumber == 0) return address(0);
        uint256 index = findUpperBound(purchasedEntries, lifeCycleData.winningTicketNumber);
        return purchasedEntries[index].owner;
    }

    /// @inheritdoc IClooverRaffle
    function nftToWin()
        public
        view
        override
        returns (IERC721 nftContractAddress, uint256 nftId)
    {
        return (config.nftContract, config.nftId);
    }

    /// @inheritdoc IClooverRaffle
    function raffleStatus()
        public
        view
        override
        returns (ClooverRaffleDataTypes.RaffleStatus)
    {
        return lifeCycleData.status;
    }


    /// @inheritdoc IClooverRaffle
    function balanceOf(address user) public view override returns (uint16[] memory) {
        if(user == address(0)) return new uint16[](0);

        ClooverRaffleDataTypes.ParticipantInfo memory participantInfo = participantInfoMap[user];
        if(participantInfo.nbOfTicketsPurchased == 0) return new uint16[](0);

        ClooverRaffleDataTypes.PurchasedEntries[] memory _purchasedEntries = purchasedEntries;
       
        uint16[] memory userTickets = new uint16[](participantInfo.nbOfTicketsPurchased);
        uint16 entriesLength = uint16(participantInfo.purchasedEntriesIndexes.length);
        for(uint16 i; i < entriesLength; ) {
            uint16 entryIndex = participantInfo.purchasedEntriesIndexes[i];
            uint16 nbOfTicketsPurchased = _purchasedEntries[entryIndex].nbOfTickets;
            uint16 startNumber = _purchasedEntries[entryIndex].currentTicketsSold - nbOfTicketsPurchased;
            for(uint16 j; j < nbOfTicketsPurchased; ){
                userTickets[i+j] = startNumber + j + 1;
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        return userTickets;
    }

    /// @inheritdoc IClooverRaffle
    function ownerOf(uint16 id) public view override returns (address) {
        if(id > currentSupply() || id == 0) return address(0);

        uint16 index = uint16(findUpperBound(purchasedEntries, id));
        return purchasedEntries[index].owner;
    }

    /// @inheritdoc IClooverRaffle
    function randomProvider() public view override returns (address) {
        return
            config.implementationManager.getImplementationAddress(
                ImplementationInterfaceNames.RandomProvider
            );
    }

    /// @inheritdoc IClooverRaffle
    function isEthRaffle() public view override returns (bool) {
        return config.isEthRaffle;
    }

    function insurancePaid() public view returns (uint256) {
        if (config.ticketSalesInsurance == 0) return 0;
        return
            _calculateInsuranceCost(
                uint256(config.ticketSalesInsurance),
                config.ticketPrice,
                uint256(config.insuranceRate)
            );
    }

    function version() public pure override returns (string memory) {
        return "1";
    }

    //----------------------------------------
    // Internals Functions
    //----------------------------------------

    /**
     * @notice check that initialize data are correct
     * @param params the struct data use for initialization
     */
    function _checkData(
        ClooverRaffleDataTypes.InitializeRaffleParams memory params
    ) internal returns(uint16, uint16, bool) {
        if (address(params.implementationManager) == address(0))
            revert Errors.NOT_ADDRESS_0();
        {
            INFTCollectionWhitelist nftWhitelist = INFTCollectionWhitelist(params
                .implementationManager
                .getImplementationAddress(
                    ImplementationInterfaceNames.NFTWhitelist
                ));
            if (!nftWhitelist.isWhitelisted(address(params.nftContract))) 
                revert Errors.COLLECTION_NOT_WHITELISTED();
        }
        address purchaseCurrencyAddress = address(params.purchaseCurrency);
        bool _isEthRaffle = purchaseCurrencyAddress == address(0);
        if (!_isEthRaffle) {
            ITokenWhitelist tokenWhitelist = ITokenWhitelist(params.implementationManager.getImplementationAddress(ImplementationInterfaceNames.TokenWhitelist));
            if (!tokenWhitelist.isWhitelisted(purchaseCurrencyAddress))
                revert Errors.TOKEN_NOT_WHITELISTED();
        }

        if (params.ticketPrice == 0) revert Errors.CANT_BE_ZERO();

        uint256 _maxTotalSupply = params.maxTotalSupply;
        if (_maxTotalSupply == 0) revert Errors.CANT_BE_ZERO();
        IConfigManager configManager = IConfigManager(
            params.implementationManager.getImplementationAddress(
                ImplementationInterfaceNames.ConfigManager
            )
        );
        if (_maxTotalSupply > configManager.maxTotalSupplyAllowed())
            revert Errors.EXCEED_MAX_VALUE_ALLOWED();

        (uint256 minDuration, uint256 maxDuration) = configManager
            .ticketSalesDurationLimits();
        uint64 ticketSaleDuration = params.ticketSalesDuration;
        if (
            ticketSaleDuration < minDuration || ticketSaleDuration > maxDuration
        ) revert Errors.OUT_OF_RANGE();

        uint256 _insuranceRate;
        uint16 ticketSalesInsurance = params.ticketSalesInsurance;
        if (ticketSalesInsurance > 0) {
            _insuranceRate = configManager.insuranceRate();
            uint256 insuranceCost = _calculateInsuranceCost(
                ticketSalesInsurance,
                params.ticketPrice,
                _insuranceRate
            );
            if (_isEthRaffle) {
                if (msg.value != insuranceCost)
                    revert Errors.INSURANCE_AMOUNT();
            } else {
                if(params.purchaseCurrency.balanceOf(address(this)) != insuranceCost)
                    revert Errors.INSURANCE_AMOUNT();
            }
        }
        if(params.royaltiesRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        uint256 _protocolFeeRate = configManager.protocolFeeRate();
        return(uint16(_insuranceRate), uint16(_protocolFeeRate), _isEthRaffle);
    }

    function _purchaseTicketInToken(uint16 nbOfTickets) internal {
        if (isEthRaffle()) revert Errors.IS_ETH_RAFFLE();
        if (nbOfTickets == 0) revert Errors.CANT_BE_ZERO();
        uint16 _maxTicketAllowedToPurchase = config.maxTicketAllowedToPurchase;
        if(_maxTicketAllowedToPurchase > 0 && participantInfoMap[msg.sender].nbOfTicketsPurchased + nbOfTickets > _maxTicketAllowedToPurchase)
            revert Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE();
       
        uint16 _currentSupply = currentSupply();
        if (_currentSupply + nbOfTickets > maxTotalSupply())
            revert Errors.TICKET_SUPPLY_OVERFLOW();
        
        uint256 ticketCost =  _calculateTicketsCost(nbOfTickets);

       

        config.purchaseCurrency.transferFrom(
            msg.sender,
            address(this),
            ticketCost
        );

        _purchaseTicket(nbOfTickets);

        emit TicketPurchased(msg.sender, _currentSupply, uint16(nbOfTickets));
    }

   /**
     * @notice attribute ticket to msg.sender
     * @param nbOfTickets the amount of ticket that the msg.sender to purchasing
     */
    function _purchaseTicket(
        uint16 nbOfTickets
    ) internal {
        uint16 purchasedEntriesIndex = uint16(purchasedEntries.length);
        uint16 currentTicketsSold = lifeCycleData.currentSupply + nbOfTickets;

        ClooverRaffleDataTypes.PurchasedEntries memory entryPurchase = ClooverRaffleDataTypes.PurchasedEntries({
            owner: msg.sender,
            currentTicketsSold: currentTicketsSold,
            nbOfTickets: nbOfTickets
        });
        purchasedEntries.push(entryPurchase);

        participantInfoMap[msg.sender].nbOfTicketsPurchased += nbOfTickets;
        participantInfoMap[msg.sender].purchasedEntriesIndexes.push(purchasedEntriesIndex);

        lifeCycleData.currentSupply = currentTicketsSold;
    }

    /**
     * @notice calculate the total price that must be paid regarding the amount of tickets to buy
     * @return amountPrice the total cost
     */
    function _calculateTicketsCost(
        uint256 nbOfTickets
    ) internal view returns (uint256 amountPrice) {
        amountPrice = config.ticketPrice * nbOfTickets;
    }

    /// https://docs.openzeppelin.com/contracts/3.x/api/utils#Arrays-findUpperBound-uint256---uint256-
    function findUpperBound(ClooverRaffleDataTypes.PurchasedEntries[] memory array, uint256 ticketNumberToSearch) internal pure returns (uint256) {
        if (array.length == 0) return 0;

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (array[mid].currentTicketsSold > ticketNumberToSearch) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        if (low > 0 && array[low - 1].currentTicketsSold == ticketNumberToSearch) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @notice calculate the amount in insurance creator paid
     * @param ticketSalesInsurance is the amount of ticket cover by the insurance
     * @param ticketCost is the price of one ticket
     * @param insuranceRate is the percentage that the creator has to pay as insurance
     * @return insuranceCost the total cost
     */
    function _calculateInsuranceCost(
        uint256 ticketSalesInsurance,
        uint256 ticketCost,
        uint256 insuranceRate
    ) internal pure returns (uint256 insuranceCost) {
        insuranceCost = (ticketSalesInsurance * ticketCost).percentMul(
            insuranceRate
        );
    }

    function _calculateAmountToTransfer(
        uint256 ticketSalesAmount
    )
        internal
        view
        returns (uint256 creatorAmount, uint256 protocolFeesAmount, uint256 royaltiesAmount)
    {
        protocolFeesAmount = ticketSalesAmount.percentMul(
            uint256(config.protocolFeeRate)
        );
        royaltiesAmount = ticketSalesAmount.percentMul(
            uint256(config.royaltiesRate)
        );
        creatorAmount = ticketSalesAmount - protocolFeesAmount - royaltiesAmount;
    }

    function _calculateUserRefundAmount() internal returns(uint256 totalRefundAmount) {
        if (currentSupply() >= config.ticketSalesInsurance) revert Errors.SALES_EXCEED_INSURANCE_LIMIT();
        
        ClooverRaffleDataTypes.ParticipantInfo memory participantInfo = participantInfoMap[msg.sender];
        if (participantInfo.hasClaimedRefund) revert Errors.ALREADY_CLAIMED();
        participantInfoMap[msg.sender].hasClaimedRefund = true;
        
        uint256 nbOfTicketPurchased = participantInfo.nbOfTicketsPurchased;
        if (nbOfTicketPurchased == 0) revert Errors.NOTHING_TO_CLAIM();

        totalRefundAmount = _calculateTicketsCost(nbOfTicketPurchased) + _calculateUserInsurancePart(nbOfTicketPurchased);
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
        returns (uint256 protocolFeeAmount, uint256 insurancePartPerTicket)
    {
        uint256 insuranceCost = _calculateInsuranceCost(
            uint256(config.ticketSalesInsurance),
            config.ticketPrice,
            uint256(config.insuranceRate)
        );

        protocolFeeAmount = insuranceCost.percentMul(uint256(config.protocolFeeRate));

        uint256 _currentSupply = currentSupply();
        insurancePartPerTicket = (insuranceCost - protocolFeeAmount) / _currentSupply;
        //Avoid dust
        protocolFeeAmount = insuranceCost - insurancePartPerTicket * _currentSupply;
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

}
