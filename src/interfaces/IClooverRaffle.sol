// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ClooverRaffleTypes} from "../libraries/Types.sol";

interface IClooverRaffleGetters {
    /// @notice Return the total amount of tickets sold
    function currentTicketSupply() external view returns (uint16);

    /// @notice Return the max amount of tickets that can be sold
    function maxTicketSupply() external view returns (uint16);

    /// @notice Return the max amount of tickets that can be sold per participant
    /// @dev 0 means no limit
    function maxTicketPerWallet() external view returns (uint16);

    /// @notice Return the address of the wallet that initiated the raffle
    function creator() external view returns (address);

    /// @notice Return the address of the token used to buy tickets
    /// @dev If the raffle is in Eth mode, this value will be address(0)
    function purchaseCurrency() external view returns (address);

    /// @notice Return if the raffle accept only ETH
    function isEthRaffle() external view returns (bool);

    /// @notice Return the price of one ticket
    function ticketPrice() external view returns (uint256);

    /// @notice Return the end time where ticket sales closing
    function endTicketSales() external view returns (uint64);

    /// @notice Return the winning ticket number
    function winningTicketNumber() external view returns (uint16);

    /// @notice get the winner address
    function winnerAddress() external view returns (address);

    /// @notice Return info regarding the nft to win
    function nftInfo() external view returns (address nftContractAddress, uint256 nftId);

    /// @notice Return the current status of the raffle
    function raffleStatus() external view returns (ClooverRaffleTypes.Status);

    /// @notice Return all tickets number own by the address
    /// @dev This function should not be call by any contract as it can be very expensive in term of gas usage due to the nested loop
    /// should be use only by front end to display the tickets number own by an address
    function getParticipantTicketsNumber(address user) external view returns (uint16[] memory);

    /// @notice Return the address that own a specific ticket number
    function ownerOf(uint16 id) external view returns (address);

    /// @notice Return the randomProvider contract address
    function randomProvider() external view returns (address);

    /// @notice Return the amount of REFUNDABLE paid by the creator
    function insurancePaid() external view returns (uint256);

    /// @notice Return the amount of ticket that is covered by the REFUNDABLE
    /// @dev If the raffle is not in REFUNDABLE mode, this value will be 0
    function minTicketThreshold() external view returns (uint16);

    /// @notice Return the royalties rate to apply on ticket sales amount to pay to the nft collection creator
    function royaltiesRate() external view returns (uint16);

    /// @notice Return the version of the contract
    function version() external pure returns (string memory);
}

interface IClooverRaffle is IClooverRaffleGetters {
    /// @notice Function to initialize contract
    function initialize(ClooverRaffleTypes.InitializeRaffleParams memory params) external payable;

    /// @notice Allows users to purchase tickets with ERC20 tokens
    function purchaseTickets(uint16 nbOfTickets) external;

    /// @notice Allows users to purchase tickets with ERC20Permit tokens
    function purchaseTicketsWithPermit(uint16 nbOfTickets, ClooverRaffleTypes.PermitDataParams calldata permitData)
        external;

    /// @notice Allows users to purchase tickets with ETH
    function purchaseTicketsInEth(uint16 nbOfTickets) external payable;

    /// @notice Request a random numbers to the RandomProvider contract
    function draw() external;

    /// @notice Select the winning ticket number using the random number from Chainlink's VRFConsumerBaseV2
    /// @dev must be only called by the RandomProvider contract
    /// function must not revert to avoid multi drawn to revert and block contract in case of wrong value received
    function draw(uint256[] memory randomNumbers) external;

    /// @notice Allows the creator to exerce the REFUNDABLE he paid in ERC20 token for and claim back his nft
    function claimCreatorRefund() external;

    /// @notice Allows the creator to exerce the REFUNDABLE he paid in Eth for and claim back his nft
    function claimCreatorRefundInEth() external;

    /// @notice Allows the creator to claim the amount link to the ticket sales in ERC20 token
    function claimTicketSales() external;

    /// @notice Allows the creator to claim the amount link to the ticket sales in Eth
    function claimTicketSalesInEth() external;

    /// @notice Allows the winner to claim his price
    function claimPrize() external;

    /// @notice Allow tickets owner to claim refund if raffle is in REFUNDABLE mode in ERC20 token
    function claimParticipantRefund() external;

    /// @notice Allow tickets owner to claim refund if raffle is in REFUNDABLE mode in Eth
    function claimParticipantRefundInEth() external;

    /// @notice Allow the creator to cancel the raffle if no ticket has been sold
    function cancel() external;
}
