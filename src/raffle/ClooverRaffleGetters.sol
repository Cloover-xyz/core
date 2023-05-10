// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ClooverRaffleTypes} from "../libraries/ClooverRaffleTypes.sol";
import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {InsuranceLib} from "../libraries/InsuranceLib.sol";

import {IClooverRaffleGetters} from "../interfaces/IClooverRaffle.sol";

import {ClooverRaffleInternal} from "./ClooverRaffleInternal.sol";

abstract contract ClooverRaffleGetters is IClooverRaffleGetters, ClooverRaffleInternal {
    using InsuranceLib for uint16;

    //----------------------------------------
    // Getter functions
    //----------------------------------------

    /// @inheritdoc IClooverRaffleGetters
    function maxTotalSupply() public view override returns (uint16) {
        return _config.maxTotalSupply;
    }

    /// @inheritdoc IClooverRaffleGetters
    function currentSupply() public view override returns (uint16) {
        return _lifeCycleData.currentSupply;
    }

    /// @inheritdoc IClooverRaffleGetters
    function creator() public view override returns (address) {
        return _config.creator;
    }

    /// @inheritdoc IClooverRaffleGetters
    function purchaseCurrency() public view override returns (IERC20) {
        return _config.purchaseCurrency;
    }

    /// @inheritdoc IClooverRaffleGetters
    function ticketPrice() public view override returns (uint256) {
        return _config.ticketPrice;
    }

    /// @inheritdoc IClooverRaffleGetters
    function endTicketSales() public view override returns (uint64) {
        return _config.endTicketSales;
    }

    /// @inheritdoc IClooverRaffleGetters
    function winningTicketNumber()
        public
        view
        override
        returns (uint16)
    {
        return _lifeCycleData.winningTicketNumber;
    }

    /// @inheritdoc IClooverRaffleGetters
    function winnerAddress()
        public
        view
        override
        returns (address)
    {
        if (_lifeCycleData.winningTicketNumber == 0) return address(0);
        return _winnerAddress();
    }

    /// @inheritdoc IClooverRaffleGetters
    function nftInfo()
        public
        view
        override
        returns (IERC721 nftContractAddress, uint256 nftId)
    {
        return (_config.nftContract, _config.nftId);
    }

    /// @inheritdoc IClooverRaffleGetters
    function raffleStatus()
        public
        view
        override
        returns (ClooverRaffleTypes.Status)
    {
        return _lifeCycleData.status;
    }


    /// @inheritdoc IClooverRaffleGetters
    function balanceOf(address user) public view override returns (uint16[] memory) {
        if(user == address(0)) return new uint16[](0);

        ClooverRaffleTypes.ParticipantInfo memory participantInfo = _participantInfoMap[user];
        if(participantInfo.nbOfTicketsPurchased == 0) return new uint16[](0);

        ClooverRaffleTypes.PurchasedEntries[] memory entries = _purchasedEntries;
       
        uint16[] memory userTickets = new uint16[](participantInfo.nbOfTicketsPurchased);
        uint16 entriesLength = uint16(participantInfo.purchasedEntriesIndexes.length);
        for(uint16 i; i < entriesLength; ) {
            uint16 entryIndex = participantInfo.purchasedEntriesIndexes[i];
            uint16 nbOfTicketsPurchased = entries[entryIndex].nbOfTickets;
            uint16 startNumber = entries[entryIndex].currentTicketsSold - nbOfTicketsPurchased;
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

    /// @inheritdoc IClooverRaffleGetters
    function ownerOf(uint16 id) public view override returns (address) {
        if(id > _lifeCycleData.currentSupply || id == 0) return address(0);

        uint16 index = uint16(findUpperBound(_purchasedEntries, id));
        return _purchasedEntries[index].owner;
    }

    /// @inheritdoc IClooverRaffleGetters
    function randomProvider() public view override returns (address) {
        return
            _config.implementationManager.getImplementationAddress(
                ImplementationInterfaceNames.RandomProvider
            );
    }

    /// @inheritdoc IClooverRaffleGetters
    function isEthRaffle() public view override returns (bool) {
        return _config.isEthRaffle;
    }

    /// @inheritdoc IClooverRaffleGetters
    function insurancePaid() public view override returns (uint256) {
        return _calculateInsuranceCost();
    }

    /// @inheritdoc IClooverRaffleGetters
    function version() public pure override returns (string memory) {
        return "1";
    }
}