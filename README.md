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

This repository contains the smart contracts source code and markets configuration for Cloover Protocol.

---

## What is Cloover Raffle?

ClooverRaffle is a decentralized non-custodial NFT Raffle protocol where users can create and participate in raffle. Raffles' creators make their own NFT as winning price.

- Raffle's creator can set the number of tickets, the price of each ticket and the duration of the raffle. Creator can also set a minimum amount of ticket's sales as an insurance, if the amount of ticket's sales is under the insurance's amount, the creator can claim back the NFT.
- User can purchase tickets with token defined by the raffle's creator.
- When the raffle is over, a random winner is selected using ChainLinkVRF subscription. The winner will be able to claim the NFT and the raffle's creator to claim ticket's sales amount.
- If creator set an insurance and the amount of ticket's sales is under the insurance's amount, user can claim back their ticket's price plus a bonus link to a part of the insurance per tickets purchased.

TL;DR: Instead of selling your NFT for a fix price, you can create a raffle with your own condition (insurance, ticket prices, etc.) and let's user participate to win your NFT.

---


## Contracts overview

- [`AccessController`](./src/core/AccessController.sol)
Inherited from OpenZeppelin AccessControl.sol, this contract manage roles and permissions over the protocol.

- [`ImplementationManager`](./src/core/ImplementationManager.sol)
This contract manage all active contracts address used by the protocol. Only the MAINTAINER_ROLE can update the implementations address. It can be see as a finder for the protocol.

- [`RandomProvider`](./src/core/RandomProvider.sol)
Inherited from Chainlink VRFConsumerBaseV2, this contract is the only access point between raffles' contract and ChainLinkVRF.

- [`NFTWhitelist`](./src/core/NFTWhitelist.sol)
Used to track NFT collection that can be use to create raffle.  Only the MAINTAINER_ROLE can update the whitelist.

- [`TokenWhitelist`](./src/core/TokenWhitelist.sol)
Used to track tokens that can be use as currency for purchasing tickets in the raffle. Only the MAINTAINER_ROLE can update the whitelist.

- [`ClooverRaffleFactory`](./src/raffleFactory/ClooverRaffleFactory.sol)
The first entry point for user to interact with the protocol. It's the contract that manage the raffle creation. It inherits from several contract: 
    - [`ClooverRaffleFactoryGetters`](./src/raffleFactory/ClooverRaffleGetters.sol) contains all the functions used to get raffles' max configuration set by the protocol.
    - [`ClooverRaffleFactorySetters`](./src/raffleFactory/ClooverRaffleSetters.sol) contains all the functions used by the governance to manage the raffle
    - [`ClooverRaffleFactoryStorage`](./src/raffleFactory/ClooverRaffleFactoryStorage.sol) where storage is located.

Each raffle created is a clone of the `ClooverRaffle` contract that handle a single raffle lifecycle. The contract will be initialize with the raffle's parameters and the raffle's creator will be the owner of the contract.

- [`ClooverRaffle`](./src/raffle/ClooverRaffle.sol)
The main entry point for user to interact with the protocol. Each ClooverRaffle contract is link to one raffle in order to avoid security issue. It inherits from several contract: 
    - [`ClooverRaffleGetters`](./src/raffle/ClooverRaffleGetters.sol) contains all the functions used to get raffle configuration and current data.
    - [`ClooverRaffleInternal`](./src/raffle/ClooverRaffleInternal.sol) contains all the logic functions used by the raffle.
    - [`ClooverRaffleStorage`](./src/raffle/ClooverRaffleStorage.sol) where storage is located.

---

## Deployment Addresses

### Cloover Protocol (Sepolia)

- AccessController: [0xce02489f63AA63e2316452628Bb2E457CAC54d0C](https://sepolia.etherscan.io/address/0xce02489f63AA63e2316452628Bb2E457CAC54d0C)
- ImplementationManager: [0xEed7187bc58344BA5c36dc7bCe13177C261AF41B](https://sepolia.etherscan.io/address/0xEed7187bc58344BA5c36dc7bCe13177C261AF41B)
- NFTWhitelist: [0xBc774c97c15a6ee7bb97ee55c6796C086F7D6079](https://sepolia.etherscan.io/address/0xBc774c97c15a6ee7bb97ee55c6796C086F7D6079)
- TokenWhitelist: [0x89cb912D94fB41b10477042F25d55E9b7E55ac25](https://sepolia.etherscan.io/address/0x89cb912D94fB41b10477042F25d55E9b7E55ac25)
- RandomProvider: [0x2dD9603384ee5F1EA1b3614cf0d46a040418CCdA](https://sepolia.etherscan.io/address/0x2dD9603384ee5F1EA1b3614cf0d46a040418CCdA)
- ClooverRaffleFactory: [0xfB739b76f8925EC9543a2b75e7F5993DB28fb613](https://sepolia.etherscan.io/address/0xfB739b76f8925EC9543a2b75e7F5993DB28fb613)

---

## Development

### Getting Started

- Install [Foundry](https://github.com/foundry-rs/foundry).
- Run `make install` to initialize the repository.
- Create a `.env` file according to the [`.env.example`](./.env.example) file.

### Testing with [Foundry](https://github.com/foundry-rs/foundry) 🔨

For testing, make sure `foundry` is installed and install dependencies (git submodules) with:

```bash
make install
```

To run the whole test suite:

```bash
make test
```

or to run only tests matching an input:

```bash
make test-PurchaseTickets
```

or to run only tests matching a contract:
    
```bash
make test/ClooverRaffle
```

For the other commands, check the [Makefile](./Makefile).

### VSCode setup

Configure your VSCode to automatically format a file on save, using `forge fmt`:

- Install [emeraldwalk.runonsave](https://marketplace.visualstudio.com/items?itemName=emeraldwalk.RunOnSave)
- Update your `settings.json`:

```json
{
  "[solidity]": {
    "editor.formatOnSave": false
  },
  "emeraldwalk.runonsave": {
    "commands": [
      {
        "match": ".sol",
        "isAsync": true,
        "cmd": "forge fmt ${file}"
      }
    ]
  }
}
```


---

## Test coverage

Test coverage is reported using [foundry](https://github.com/foundry-rs/foundry) coverage with [lcov](https://github.com/linux-test-project/lcov) report formatting (and optionally, [genhtml](https://manpages.ubuntu.com/manpages/xenial/man1/genhtml.1.html) transformer).

To generate the `lcov` report, run:

```bash
make coverage
```

The report is then usable either:

- via [Coverage Gutters](https://marketplace.visualstudio.com/items?itemName=ryanluker.vscode-coverage-gutters) following [this tutorial](https://mirror.xyz/devanon.eth/RrDvKPnlD-pmpuW7hQeR5wWdVjklrpOgPCOA-PJkWFU)
- via html, using `make lcov-html` to transform the report and opening `coverage/index.html`


---

## Licensing

The code is under the GNU AFFERO GENERAL PUBLIC LICENSE v3.0, see [`LICENSE`](./LICENSE).