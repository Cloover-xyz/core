// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title ClooverRaffleTypes
/// @author Cloover
/// @notice Library exposing all Types used in ClooverRaffle & ClooverRaffleFactory.
library ClooverRaffleTypes {
    /* ENUMS */
    /// @notice Enumeration of the different status of the raffle
    enum Status {
        DEFAULT,
        DRAWNING,
        DRAWN,
        INSURANCE,
        CANCELLED
    }

    /* STORAGE STRUCTS */

    /// @notice Contains the immutable config of a raffle
    struct ConfigData {
        address creator;
        address implementationManager;
        address purchaseCurrency;
        address nftContract;
        uint256 nftId;
        uint256 ticketPrice;
        uint64 endTicketSales;
        uint16 maxTotalSupply;
        uint16 maxTicketAllowedToPurchase;
        uint16 ticketSalesInsurance;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint16 royaltiesRate;
        bool isEthRaffle;
    }

    /// @notice Contains the current state of the raffle
    struct LifeCycleData {
        Status status;
        uint16 currentSupply;
        uint16 winningTicketNumber;
    }

    /// @notice Contains the info of a purchased entry
    struct PurchasedEntries {
        address owner;
        uint16 currentTicketsSold; // Current amount of tickets sold with new purchase
        uint16 nbOfTickets; // number of tickets purchased
    }

    ///@notice Contains the info of a participant
    struct ParticipantInfo {
        uint16 nbOfTicketsPurchased;
        uint16[] purchasedEntriesIndexes;
        bool hasClaimedRefund;
    }

    /// @notice Contains the base info and limit for raffles
    struct FactoryConfig {
        uint16 maxTotalSupplyAllowed;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint64 minTicketSalesDuration;
        uint64 maxTicketSalesDuration;
    }

    /* STACK AND RETURN STRUCTS */

    /// @notice The parameters used by the raffle factory to create a new raffle
    struct CreateRaffleParams {
        address purchaseCurrency;
        address nftContract;
        uint256 nftId;
        uint256 ticketPrice;
        uint64 ticketSalesDuration;
        uint16 maxTotalSupply;
        uint16 maxTicketAllowedToPurchase;
        uint16 ticketSalesInsurance;
        uint16 royaltiesRate;
    }

    /// @notice The parameters used for ERC20 permit function
    struct PermitDataParams {
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice The parameters used to initialize the raffle
    struct InitializeRaffleParams {
        address creator;
        address implementationManager;
        address purchaseCurrency;
        address nftContract;
        uint256 nftId;
        uint256 ticketPrice;
        uint64 ticketSalesDuration;
        uint16 maxTotalSupply;
        uint16 maxTicketAllowedToPurchase;
        uint16 ticketSalesInsurance;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint16 royaltiesRate;
        bool isEthRaffle;
    }

    /// @notice The parameters used to initialize the raffle factory
    struct FactoryConfigParams {
        uint16 maxTotalSupplyAllowed;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint64 minTicketSalesDuration;
        uint64 maxTicketSalesDuration;
    }
}

/// @title RandomProviderTypes
/// @author Cloover
/// @notice Library exposing all Types used in RandomProvider.
library RandomProviderTypes {
    struct ChainlinkVRFData {
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        address vrfCoordinator;
        // The gas lane to use, which specifies the maximum gas price to bump to.
        // For a list of available gas lanes on each network,
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        bytes32 keyHash;
        // A reasonable default is 100000, but this value could be different
        // on other networks.
        uint32 callbackGasLimit;
        // The default is 3, but you can set this higher.
        uint16 requestConfirmations;
        uint64 subscriptionId;
    }
}
