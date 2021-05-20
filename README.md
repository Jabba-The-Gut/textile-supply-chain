# Textile Supply Chain using Ethereum
[![forthebadge](https://forthebadge.com/images/badges/built-with-love.svg)](https://forthebadge.com)
[![forthebadge](https://forthebadge.com/images/badges/powered-by-coffee.svg)](https://forthebadge.com)
[![forthebadge](https://forthebadge.com/images/badges/check-it-out.svg)](https://forthebadge.com)

This repository contains the sources of my bachelor thesis where I developed a etherum based blockchain prototype to enhance the chain of custody and to make it possible for an exemplary organization to check their supply chain against the rules of the ["Lieferkettengesetz"](https://lieferkettengesetz.de/).

The supply chain of the exemplary organization consists of 4 tiers and multiple suppliers. Every entity has an associated wallet and can interact with the blockchain prototype to simulate a supply chain. Physical goods are represented using a digital twin that moves along the suppl chain as the phyiscal good does. This digital twin is realised using a [ERC-721 token](https://ethereum.org/en/developers/docs/standards/tokens/erc-721/). The following graphic should give an overview of the situation:

![Bildschirmfoto 2021-05-20 um 13 49 10](https://user-images.githubusercontent.com/29917858/118973629-29956900-b972-11eb-84f4-8ee6be03c8e1.png)

## Prototype 
The prototype consists of the following parts:
- a truffle project
- an ethereum blockchain provided by ganache
- a Node-RED project to visually interact with the blockchain

The following screenshot shows an example flow with multiple nodes defined in the Node-RED project:

![Bildschirmfoto 2021-05-20 um 13 55 04](https://user-images.githubusercontent.com/29917858/118974333-fdc6b300-b972-11eb-9ece-862d407d08a9.png)

### Accounts & Roles
The blockchain has 20 associated accounts with predefined roles. The following table displays the addresses and the roles: 

|Address  |Role   	|
|---	|---	|
| 0x443007D52e3E285E54FD2F470aaDFFCF7d76A195  	|Admin, Minter   	|
| 0x90c9425330fC35D63533be3a5B15d95771DedE20  	|Admin   	|
| 0xDa38E26ef4d89617A1f26179A78813869F46a5DB  	|Minter, Supply Chain Entity   	|
| 0xF18Cd3C0Fc23dfB6A17539352dAB870AfD461904  	|Minter, Supply Chain Entity   	|
| 0x0942269301f2FD774d794D6aA7865c376511FB3E  	|Minter, Supply Chain Entity   	|
| 0x860D9b0868f498a7A107430929466246Dec92Efd  	|Minter, Supply Chain Entity   	|
| 0xC3F76ebFC4eE489B0f9F05B4C9662741738267c6  	|Control, Supply Chain Entity   	|
| 0x9e1595E3224feda3800fD5c3C1F52Fd5BF21A163  	|Minter, Supply Chain Entitiy   	|
| Other addresses  	|Supply Chain Entity   	|

- Admin role = Supply Chain administrator
- Minter role = Can mint new tokens, represents a producer in the supply chain
- Control role = Controls the circumstances along the supply chain
- Supply Chain Entity role = Base role. If this is the only role, it means the account represents a delivery instance

### Smart Contracts
There are 4 Smart Contracts to simulate a supply chain:
- **ChainOfCustodyToken**: The token that is the digital twin for physical goods. Is used to mint new tokens and to transfer the tokens between entities
- **Control**: Enables the controllers to start and manage a control made for one of the entities
- **LKGRegistry**: The base registry that is the main data store. It holds references to all entities and their states. Is used to query circumstances or to administrate the supply chain
- **RBAC**: The contract that defines the roles (Role Based Access Control). It is not necessery to directly interact with it, because the 20 accounts already have the necessary roles

The Node-RED project contains a flow for every contract. Every flow has a description provided:

![Bildschirmfoto 2021-05-20 um 14 21 01](https://user-images.githubusercontent.com/29917858/118977587-9ca0de80-b976-11eb-8dd2-b946dddcb316.png)



