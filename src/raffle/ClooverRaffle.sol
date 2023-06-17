// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC20, SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";
import {Permit2Lib} from "@permit2/libraries/Permit2Lib.sol";

import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/Errors.sol";
import {PercentageMath} from "../libraries/PercentageMath.sol";
import {ClooverRaffleTypes} from "../libraries/Types.sol";
import {ClooverRaffleEvents} from "../libraries/Events.sol";

import {IClooverRaffle} from "../interfaces/IClooverRaffle.sol";
import {IClooverRaffleFactory} from "../interfaces/IClooverRaffleFactory.sol";
import {IRandomProvider} from "../interfaces/IRandomProvider.sol";
import {INFTWhitelist} from "../interfaces/INFTWhitelist.sol";
import {ITokenWhitelist} from "../interfaces/ITokenWhitelist.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";

import {ClooverRaffleStorage} from "./ClooverRaffleStorage.sol";
import {ClooverRaffleGetters} from "./ClooverRaffleGetters.sol";
import {ClooverRaffleInternal} from "./ClooverRaffleInternal.sol";

/// @title ClooverRaffle
/// @author Cloover
/// @notice The main Raffle contract exposing all user entry points.
contract ClooverRaffle is IClooverRaffle, Initializable, ClooverRaffleGetters {
    using PercentageMath for uint256;
    using SafeTransferLib for ERC20;
    using Permit2Lib for ERC20;

    //----------------------------------------
    // Modifiers
    //----------------------------------------

    modifier ticketSalesOpen() {
        if (block.timestamp >= _config.endTicketSales) revert Errors.RAFFLE_CLOSE();
        _;
    }

    modifier ticketSalesOver() {
        if (block.timestamp < _config.endTicketSales) {
            revert Errors.RAFFLE_STILL_OPEN();
        }
        _;
    }

    modifier ticketHasNotBeDrawn() {
        if (_lifeCycleData.status == ClooverRaffleTypes.Status.DRAWN) revert Errors.TICKET_ALREADY_DRAWN();
        _;
    }

    modifier winningTicketDrawn() {
        if (_lifeCycleData.status != ClooverRaffleTypes.Status.DRAWN) revert Errors.TICKET_NOT_DRAWN();
        _;
    }

    modifier onlyCreator() {
        if (_config.creator != msg.sender) {
            revert Errors.NOT_CREATOR();
        }
        _;
    }

    //----------------------------------------
    // Initializer
    //----------------------------------------

    function initialize(ClooverRaffleTypes.InitializeRaffleParams calldata params)
        external
        payable
        override
        initializer
    {
        _config = ClooverRaffleTypes.ConfigData({
            creator: params.creator,
            implementationManager: params.implementationManager,
            purchaseCurrency: params.purchaseCurrency,
            nftContract: params.nftContract,
            nftId: params.nftId,
            ticketPrice: params.ticketPrice,
            endTicketSales: params.endTicketSales,
            maxTicketSupply: params.maxTicketSupply,
            minTicketThreshold: params.minTicketThreshold,
            maxTicketPerWallet: params.maxTicketPerWallet,
            protocolFeeRate: params.protocolFeeRate,
            insuranceRate: params.insuranceRate,
            royaltiesRate: params.royaltiesRate,
            isEthRaffle: params.isEthRaffle
        });
    }

    //----------------------------------------
    // Externals Functions
    //----------------------------------------

    /// @inheritdoc IClooverRaffle
    function purchaseTickets(uint16 nbOfTickets) external override ticketSalesOpen {
        _purchaseTicketsInToken(nbOfTickets);
    }

    /// @inheritdoc IClooverRaffle
    function purchaseTicketsWithPermit(uint16 nbOfTickets, ClooverRaffleTypes.PermitDataParams calldata permitData)
        external
        override
        ticketSalesOpen
    {
        ERC20(_config.purchaseCurrency).permit(
            msg.sender, address(this), permitData.amount, permitData.deadline, permitData.v, permitData.r, permitData.s
        );
        _purchaseTicketsInToken(nbOfTickets);
    }

    /// @inheritdoc IClooverRaffle
    function purchaseTicketsInEth(uint16 nbOfTickets) external payable override ticketSalesOpen {
        if (!_config.isEthRaffle) revert Errors.NOT_ETH_RAFFLE();
        if (_calculateTicketsCost(nbOfTickets) != msg.value) {
            revert Errors.WRONG_MSG_VALUE();
        }
        _purchaseTickets(nbOfTickets);
    }

    /// @inheritdoc IClooverRaffle
    function draw() external override ticketSalesOver {
        if (uint256(_lifeCycleData.status) >= uint256(ClooverRaffleTypes.Status.DRAWNING)) {
            revert Errors.DRAW_NOT_POSSIBLE();
        }
        uint16 _currentSupply = _lifeCycleData.currentTicketSupply;
        if (_currentSupply == 0) {
            _lifeCycleData.status = ClooverRaffleTypes.Status.CANCELLED;
        } else if (_currentSupply < _config.minTicketThreshold) {
            _lifeCycleData.status = ClooverRaffleTypes.Status.REFUNDABLE;
        } else {
            _lifeCycleData.status = ClooverRaffleTypes.Status.DRAWNING;
            IRandomProvider(
                IImplementationManager(_config.implementationManager).getImplementationAddress(
                    ImplementationInterfaceNames.RandomProvider
                )
            ).requestRandomNumbers(1);
        }
        emit ClooverRaffleEvents.RaffleStatus(_lifeCycleData.status);
    }

    /// @inheritdoc IClooverRaffle
    function draw(uint256[] calldata randomNumbers) external override {
        if (
            IImplementationManager(_config.implementationManager).getImplementationAddress(
                ImplementationInterfaceNames.RandomProvider
            ) != msg.sender
        ) revert Errors.NOT_RANDOM_PROVIDER_CONTRACT();

        if (randomNumbers[0] == 0) {
            _lifeCycleData.status = ClooverRaffleTypes.Status.OPEN;
        } else {
            uint16 winningTicketNumber = uint16((randomNumbers[0] % _lifeCycleData.currentTicketSupply) + 1);
            _lifeCycleData.winningTicketNumber = winningTicketNumber;
            _lifeCycleData.status = ClooverRaffleTypes.Status.DRAWN;
            emit ClooverRaffleEvents.WinningTicketDrawn(winningTicketNumber);
        }
        emit ClooverRaffleEvents.RaffleStatus(_lifeCycleData.status);
    }

    /// @inheritdoc IClooverRaffle
    function claimTicketSales() external override winningTicketDrawn onlyCreator {
        if (_config.isEthRaffle) revert Errors.IS_ETH_RAFFLE();
        ERC20 purchaseCurrency = ERC20(_config.purchaseCurrency);
        IImplementationManager _implementationManager = IImplementationManager(_config.implementationManager);

        (uint256 creatorAmount, uint256 protocolFees, uint256 royaltiesAmount) =
            _calculateAmountToTransfer(purchaseCurrency.balanceOf(address(this)));

        purchaseCurrency.safeTransfer(
            _implementationManager.getImplementationAddress(ImplementationInterfaceNames.Treasury), protocolFees
        );

        if (royaltiesAmount > 0) {
            purchaseCurrency.safeTransfer(
                INFTWhitelist(
                    _implementationManager.getImplementationAddress(ImplementationInterfaceNames.NFTWhitelist)
                ).getCollectionCreator(address(_config.nftContract)),
                royaltiesAmount
            );
        }

        purchaseCurrency.safeTransfer(msg.sender, creatorAmount);

        emit ClooverRaffleEvents.CreatorClaimed(creatorAmount, protocolFees, royaltiesAmount);
    }

    /// @inheritdoc IClooverRaffle
    function claimTicketSalesInEth() external override winningTicketDrawn onlyCreator {
        if (!_config.isEthRaffle) revert Errors.NOT_ETH_RAFFLE();
        IImplementationManager _implementationManager = IImplementationManager(_config.implementationManager);

        (uint256 creatorAmount, uint256 protocolFees, uint256 royaltiesAmount) =
            _calculateAmountToTransfer(address(this).balance);

        SafeTransferLib.safeTransferETH(
            _implementationManager.getImplementationAddress(ImplementationInterfaceNames.Treasury), protocolFees
        );

        if (royaltiesAmount > 0) {
            SafeTransferLib.safeTransferETH(
                INFTWhitelist(
                    _implementationManager.getImplementationAddress(ImplementationInterfaceNames.NFTWhitelist)
                ).getCollectionCreator(address(_config.nftContract)),
                royaltiesAmount
            );
        }

        SafeTransferLib.safeTransferETH(msg.sender, creatorAmount);

        emit ClooverRaffleEvents.CreatorClaimed(creatorAmount, protocolFees, royaltiesAmount);
    }

    /// @inheritdoc IClooverRaffle
    function claimPrize() external override winningTicketDrawn {
        if (msg.sender != _winnerAddress()) {
            revert Errors.MSG_SENDER_NOT_WINNER();
        }
        ERC721(_config.nftContract).safeTransferFrom(address(this), msg.sender, _config.nftId);
        emit ClooverRaffleEvents.WinnerClaimed(msg.sender);
    }

    /// @inheritdoc IClooverRaffle
    function claimParticipantRefund() external override ticketSalesOver ticketHasNotBeDrawn {
        if (_config.isEthRaffle) revert Errors.IS_ETH_RAFFLE();

        uint256 totalRefundAmount = _calculateUserRefundAmount();

        ERC20(_config.purchaseCurrency).safeTransfer(msg.sender, totalRefundAmount);

        emit ClooverRaffleEvents.UserClaimedRefund(msg.sender, totalRefundAmount);
    }

    /// @inheritdoc IClooverRaffle
    function claimParticipantRefundInEth() external override ticketSalesOver ticketHasNotBeDrawn {
        if (!_config.isEthRaffle) revert Errors.NOT_ETH_RAFFLE();

        uint256 totalRefundAmount = _calculateUserRefundAmount();

        SafeTransferLib.safeTransferETH(msg.sender, totalRefundAmount);

        emit ClooverRaffleEvents.UserClaimedRefund(msg.sender, totalRefundAmount);
    }

    /// @inheritdoc IClooverRaffle
    function claimCreatorRefund() external override ticketSalesOver ticketHasNotBeDrawn onlyCreator {
        if (_config.isEthRaffle) revert Errors.IS_ETH_RAFFLE();

        (uint256 treasuryAmountToTransfer, address treasuryAddress) = _handleCreatorInsurance();

        ERC20(_config.purchaseCurrency).safeTransfer(treasuryAddress, treasuryAmountToTransfer);

        ERC721(_config.nftContract).safeTransferFrom(address(this), _config.creator, _config.nftId);

        emit ClooverRaffleEvents.CreatorClaimedRefund();
    }

    /// @inheritdoc IClooverRaffle
    function claimCreatorRefundInEth() external override ticketSalesOver ticketHasNotBeDrawn onlyCreator {
        if (!_config.isEthRaffle) revert Errors.NOT_ETH_RAFFLE();

        (uint256 treasuryAmountToTransfer, address treasuryAddress) = _handleCreatorInsurance();

        SafeTransferLib.safeTransferETH(treasuryAddress, treasuryAmountToTransfer);

        ERC721(_config.nftContract).safeTransferFrom(address(this), _config.creator, _config.nftId);
        emit ClooverRaffleEvents.CreatorClaimedRefund();
    }

    /// @inheritdoc IClooverRaffle
    function cancel() external override onlyCreator {
        if (_lifeCycleData.currentTicketSupply > 0) revert Errors.SALES_ALREADY_STARTED();
        if (_lifeCycleData.status != ClooverRaffleTypes.Status.CANCELLED) {
            _lifeCycleData.status = ClooverRaffleTypes.Status.CANCELLED;
            emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.CANCELLED);
        }
        IClooverRaffleFactory(
            IImplementationManager(_config.implementationManager).getImplementationAddress(
                ImplementationInterfaceNames.ClooverRaffleFactory
            )
        ).removeRaffleFromRegister();

        if (_config.minTicketThreshold > 0) {
            uint256 insurancePaid = _calculateInsuranceCost();
            if (_config.isEthRaffle) {
                SafeTransferLib.safeTransferETH(_config.creator, insurancePaid);
            } else {
                ERC20(_config.purchaseCurrency).safeTransfer(_config.creator, insurancePaid);
            }
        }

        ERC721(_config.nftContract).safeTransferFrom(address(this), _config.creator, _config.nftId);
        emit ClooverRaffleEvents.RaffleCancelled();
    }
}
