```
 ::::::::  :::         ::::::::   ::::::::  :::     ::: :::::::::: :::::::::
:+:    :+: :+:        :+:    :+: :+:    :+: :+:     :+: :+:        :+:    :+:
+:+        +:+        +:+    +:+ +:+    +:+ +:+     +:+ +:+        +:+    +:+
+#+        +#+        +#+    +:+ +#+    +:+ +#+     +:+ +#++:++#   +#++:++#:
+#+        +#+        +#+    +#+ +#+    +#+  +#+   +#+  +#+        +#+    +#+
#+#    #+# #+#        #+#    #+# #+#    #+#   #+#+#+#   #+#        #+#    #+#
 ########  ##########  ########   ########      ###     ########## ###    ###

```
# Cloover Protocol

This repository contains the smart contracts source code and markets configuration for Cloover Protocol. The repository uses Foundry as development environment for compilation, testing and Hardhat as deployment tasks.

## What is Cloover ?

Cloover is a decentralized non-custodial NFT Raffle protocol where users can create and participate in raffle. Raffles' creators make their own NFT as winning price.

## Protocol Overview

1. `AccessController.sol`
Inherited from OpenZeppelin AccessControl.sol, it's the contract that manage the roles and permissions of the protocol.

2. `ConfigManager.sol`
It's the contract that manage the configuration of the protocol. Only the MAINTAINER_ROLE can update the configuration.

3. `RandomProvider.sol`
It's the contract that manage the random number generation for the raffles. It's the access point to Chainlink VRF.

4. `ImplementationMaanger.sol`
It's the contract that manage the implementation of the protocol. Only the MAINTAINER_ROLE can update the implementations address.
It can be see as a finder for the protocol.

5. `NFTCollectionWhitelist.sol`
It's the contract that manage the whitelist of NFT collection that can be use for the raffles. Only the MAINTAINER_ROLE can update the whitelist.

6. `TokenWhitelist.sol`
It manage the whitelist of tokens that can be use as currency for the raffles. Only the MAINTAINER_ROLE can add/remove token.

7. `RaffleFactory.sol`
Deploy new raffle using OpenZeppelin Clone() function. It's the access point for raffles creation.

8. `Raffle.sol`
It's the contract that manage the raffle. Each raffle created is a clone of this contract that handle a single raffle lifecycle. The contract will be initialize with the raffle's parameters and the raffle's creator will be the owner of the contract.
 
    1. Raffles' creators can specify several options during the creation:
        - number of tickets on sale for the raffle (mandatory)
        - ticket price (mandatory)
        - purchase currency accepted (mandatory)
        - period of time of purchase ticket (mandatory)
        - max amount of ticket allow to purchase per wallet (optional)
        - percentage of royalties sent to nft collection creator (optional)
        - minimum ticket that need to be sold for the raffle as insurance (optional)

        Creators may cancel their raffle if not ticket has been sold, in that case they will receive back their NFT and the insurance amount paid if if was taken.
        In case creators have taken out insurance and the amount of tickets sold didn't reached the minimum specified, creators can claim their insurance and get back the NFT but will loose the insurance amount paid.


    2. Raffles' participants can purchase raffle tickets in the currency specify by the creator.
        When winning ticket is draw, the winner can claim the NFT.
        In case the raffle has an insurance and the amount of ticket sold it's under it level, participants can claim back their investment with a small bonus coming from the insurance paid by the creator.


## Setup

The repository uses Foundry, hardhat and yarn.

Follow the next steps to setup the repository:

- Install [foundry]('https://book.getfoundry.sh/getting-started/installation') and [yarn]('https://classic.yarnpkg.com/lang/en/docs/install/#mac-stable')

- Create an environment file named `.env` and fill the next environment variables

```shell
# Wallet that will be use for deployment
PRIVATE_KEY=""
# Networks RPC for deployment
SEPOLIA_RPC_URL=""
# Required for etherscan verification
ETHERSCAN_KEY=""
# Required for RandomProvider.sol
CHAINLINK_VRF_SUBSCRIPTION_ID=""
```

- verify that everything compile:
```shell
yarn && yarn build
```

## Tests

You can run the full test suite with the following commands:

```shell
yarn test
```

For test coverage run: 
```shell
yarn coverage
```