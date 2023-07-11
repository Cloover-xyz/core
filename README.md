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

- Raffle's creator can specify the total number of tickets, the cost of a ticket and the duration of the raffle.
- User can purchase tickets with token defined by the raffle's creator.
- When the raffle is over, a random winner is selected using ChainLinkVRF V2. The winner will be able to claim the NFT and the raffle's creator to claim ticket's sales amount.
- In case the creator has specified a minimum amount of ticket that need to be sold, he will have to pay a part of the expected amount raised. If the minimum amount of ticket is not reached, creator can claim back his NFT and participants can claim back their ticket's price plus a bonus link to a part of the amount the creator has paid per tickets purchased. If the minimum amount of ticket is reached the raffle can be complete and the winner can claim the NFT.

TL;DR: Instead of selling your NFT for a fix price, you can create a raffle with your own condition (minium ticket , ticket prices, etc.) and let's user participate to win your NFT.

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

- AccessController: [0x889aFb8B59474E66DD4a4712b630578122bf3DA1](https://sepolia.etherscan.io/address/0x889aFb8B59474E66DD4a4712b630578122bf3DA1)
- ImplementationManager: [0x8cba63fd2fd3163385fdf1ae309ed4cf7b8d144d](https://sepolia.etherscan.io/address/0x8cba63fd2fd3163385fdf1ae309ed4cf7b8d144d)
- NFTWhitelist: [0xcaccc829ff7415f5830b499ccf07e12a72024176](https://sepolia.etherscan.io/address/0xcaccc829ff7415f5830b499ccf07e12a72024176)
- TokenWhitelist: [0xa44080a32b04755e71a8b5eca367c1430aa5530c](https://sepolia.etherscan.io/address/0xa44080a32b04755e71a8b5eca367c1430aa5530c)
- RandomProvider: [0x22A4AaaF543C55b914cf48AE6A75e38D8F13A3d8](https://sepolia.etherscan.io/address/0x22A4AaaF543C55b914cf48AE6A75e38D8F13A3d8)
- ClooverRaffleFactory: [0x5fc9f180DEE73270D7251CB3C261f4AF518271c6](https://sepolia.etherscan.io/address/0x5fc9f180DEE73270D7251CB3C261f4AF518271c6)
- MockERC20: [0x0fa5de3c90a63f6b22aa6f2b2fc29f147216ed02](https://sepolia.etherscan.io/address/0x0fa5de3c90a63f6b22aa6f2b2fc29f147216ed02)
- MockERC721: [0xbc553b7acd7dfd21d7d82f592971ea5508b1a90c](https://sepolia.etherscan.io/address/0xbc553b7acd7dfd21d7d82f592971ea5508b1a90c)

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