// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ClooverRaffleDataTypes} from '../libraries/types/ClooverRaffleDataTypes.sol';
import {ClooverRaffle} from '../raffle/ClooverRaffle.sol';

interface IClooverRaffleFactory {

    /**
     * @notice Deploy a new raffle contract
     * @dev must transfer the nft to the contract before initialize()
     * @param params used for initialization (see Params struct in ClooverRaffleFactory.sol)
     * @return newClooverRaffle the instance of the raffle contract
     */
    function createNewRaffle(ClooverRaffleDataTypes.CreateRaffleParams memory params) external payable returns(ClooverRaffle newClooverRaffle);

    /**
     * @notice Return if the address is a raffle deployed by this factory
     * @param raffleAddress the address to check
     * @return bool is true if it's a raffle deployed by this factory, false otherwise
     */
    function isRegisteredClooverRaffle(address raffleAddress) external view returns (bool);

    /**
     * @notice call by batch draw() for each raffleContract passed
     * @param raffleContracts the array of raffle addresses to call draw()
     */
    function batchClooverRaffledraw(address[] memory raffleContracts) external;

    /**
     * @notice remove msg.sender from the list of registered raffles
     */
    function deregisterClooverRaffle() external;
    
    /**
     * @notice return the version of the contract
     */
    function version() external pure returns(string memory);
}