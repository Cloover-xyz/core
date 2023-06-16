// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IClooverRaffleGetters} from "../interfaces/IClooverRaffle.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";

import {ClooverRaffleTypes} from "../libraries/Types.sol";
import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";

import {ClooverRaffleInternal} from "./ClooverRaffleInternal.sol";

/// @title ClooverRaffleGetters
/// @author Cloover
/// @notice Abstract contract exposing all accessible getters.
abstract contract ClooverRaffleGetters is IClooverRaffleGetters, IERC721Receiver, ClooverRaffleInternal {
    //----------------------------------------
    // Getter functions
    //----------------------------------------

    /// @inheritdoc IClooverRaffleGetters
    function maxTotalSupply() external view override returns (uint16) {
        return _config.maxTotalSupply;
    }

    /// @inheritdoc IClooverRaffleGetters
    function currentSupply() external view override returns (uint16) {
        return _lifeCycleData.currentSupply;
    }

    /// @inheritdoc IClooverRaffleGetters
    function maxTicketAllowedToPurchase() external view override returns (uint16) {
        return _config.maxTicketAllowedToPurchase;
    }

    /// @inheritdoc IClooverRaffleGetters
    function creator() external view override returns (address) {
        return _config.creator;
    }

    /// @inheritdoc IClooverRaffleGetters
    function purchaseCurrency() external view override returns (address) {
        return _config.purchaseCurrency;
    }

    /// @inheritdoc IClooverRaffleGetters
    function ticketPrice() external view override returns (uint256) {
        return _config.ticketPrice;
    }

    /// @inheritdoc IClooverRaffleGetters
    function endTicketSales() external view override returns (uint64) {
        return _config.endTicketSales;
    }

    /// @inheritdoc IClooverRaffleGetters
    function winningTicketNumber() external view override returns (uint16) {
        return _lifeCycleData.winningTicketNumber;
    }

    /// @inheritdoc IClooverRaffleGetters
    function winnerAddress() external view override returns (address) {
        return _winnerAddress();
    }

    /// @inheritdoc IClooverRaffleGetters
    function nftInfo() external view override returns (address nftContractAddress, uint256 nftId) {
        return (_config.nftContract, _config.nftId);
    }

    /// @inheritdoc IClooverRaffleGetters
    function raffleStatus() external view override returns (ClooverRaffleTypes.Status) {
        return _lifeCycleData.status;
    }

    /// @inheritdoc IClooverRaffleGetters
    function getParticipantTicketsNumber(address user) external view override returns (uint16[] memory) {
        ClooverRaffleTypes.ParticipantInfo memory participantInfo = _participantInfoMap[user];
        if (participantInfo.nbOfTicketsPurchased == 0) return new uint16[](0);

        ClooverRaffleTypes.PurchasedEntries[] memory entries = _purchasedEntries;

        uint16[] memory userTickets = new uint16[](participantInfo.nbOfTicketsPurchased);
        uint16 entriesLength = uint16(participantInfo.purchasedEntriesIndexes.length);
        for (uint16 i; i < entriesLength;) {
            uint16 entryIndex = participantInfo.purchasedEntriesIndexes[i];
            uint16 nbOfTicketsPurchased = entries[entryIndex].nbOfTickets;
            uint16 startNumber = entries[entryIndex].currentTicketsSold - nbOfTicketsPurchased;
            for (uint16 j; j < nbOfTicketsPurchased;) {
                userTickets[i + j] = startNumber + j + 1;
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

    /// @inheritdoc IClooverRaffleGetters
    function ownerOf(uint16 id) external view override returns (address) {
        if (id > _lifeCycleData.currentSupply || id == 0) return address(0);

        uint16 index = uint16(findUpperBound(_purchasedEntries, id));
        return _purchasedEntries[index].owner;
    }

    /// @inheritdoc IClooverRaffleGetters
    function randomProvider() external view override returns (address) {
        return IImplementationManager(_config.implementationManager).getImplementationAddress(
            ImplementationInterfaceNames.RandomProvider
        );
    }

    /// @inheritdoc IClooverRaffleGetters
    function isEthRaffle() external view override returns (bool) {
        return _config.isEthRaffle;
    }

    /// @inheritdoc IClooverRaffleGetters
    function insurancePaid() external view override returns (uint256) {
        return _calculateInsuranceCost();
    }

    /// @inheritdoc IClooverRaffleGetters
    function ticketSalesInsurance() external view override returns (uint16) {
        return _config.ticketSalesInsurance;
    }

    /// @inheritdoc IClooverRaffleGetters
    function royaltiesRate() external view override returns (uint16) {
        return _config.royaltiesRate;
    }

    /// @inheritdoc IClooverRaffleGetters
    function version() external pure override returns (string memory) {
        return "1";
    }

    /// @notice required by ERC721Receiver interface for ERC721 safeTransferFrom
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
