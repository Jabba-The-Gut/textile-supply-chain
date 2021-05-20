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

### Using the prototype
After you installed the prototype, you can interact with it in the following way using Node-RED:
- Start a control for an entity by using the **Control** flow. Make sure that the controller is one of the accounts with the Control role. 
- Simulate the producing and processing of goods with their digital twin by minting and transferring tokens in the **Chain Of Custody Token** flow. It must be noted that at the beginning, all accounts have a **GSE status** of false. This means that the accounts have not accepted the rules from the "Lieferkettengesetz" and every transaction with tokens made by these accounts adds a **NOnGSETransaction** entry to the corresponding accounts. To set the **GSE status** to true, use the **LKG Registry** flow and execute the **Acknowledge "Grundsatzerklärung"** subflow.
- Query information about entities, controls and non gse transactons using the **LKG Registry** flow 

## Installation
### Prequisites
- First, install truffle from https://www.trufflesuite.com/truffle
- Then install ganache from https://www.trufflesuite.com/ganache
- Then install Node-RED locally as described in https://nodered.org/docs/getting-started/local
- Then make sure that you have the sources from this repsoitory and the package ["node-red-contrib-ethereum"](https://github.com/timweing/node-red-contrib-ethereum) available locally 

### Node-RED
The nodes to interact with an ethererum blockchain are in the "node-red-contrib-ethereum" package and need to be added to your Node-RED installation. For this:
- Locate the .node-red directory on your system. It is usually located in your user directory. If not, then make sure that you start Node-RED before checking again. Node-RED can be started with the following command:
```bash
node-red
```
- Then run the following command from inside the .node-red directory: 
```bash
npm install [path to the location of node-red-contrib-ethereum
```
- Now start Node-RED and use to URL from the start command (usually http://127.0.0.1:1880) to check if the following nodes are present:

![Bildschirmfoto 2021-05-20 um 15 40 52](https://user-images.githubusercontent.com/29917858/118988763-c6133780-b981-11eb-82f0-4755924f077e.png)

### Ganache
Now you need to set up a new ganache workspace that hosts your local ethereum blockchain.
- Open Ganache and select "New Workspace"
- In the "Workspace"-Tab choose a name and then click on the **Add Project** button to link a new truffle project. In the dialogue, choose the ```truffle-config.js``` from this repository. By adding this truffle project, you are able to see information in ganache such as smart contract address later on
- In the "Server"-Tab make sure that you set the **Network ID** to ```4444```. Otherwise Node-RED will not be able to connect to your blockchain
- In the "Accounts & Keys"-Tab set the number of total accounts to **20** and replace the choosen Mnemonic with the following:
```
neither thank differ pigeon link arctic nephew excess ahead present because rely
```
This Mnemonic is used by ganache to create the addresses. This makes sure that you have the same addresses as me
- Click on "Save Workspace"
Note: If you use Node-RED, then the created workspace must be the active one

### Truffle
Now you need to deploy the smart contracts to ganache, so they are available. The file ```migrations.js```contains the needed logic to deploy the contracts and also set's up the needed roles for the different addresses.
- Run the following commands from the directory that contains the ```truffle-config.js```from this repository:
```bash
truffle compile --all
```
```bash
truffle migrate --network ganache
```
The migrate command should display something like this:
![Bildschirmfoto 2021-05-20 um 16 01 33](https://user-images.githubusercontent.com/29917858/118992145-a92c3380-b984-11eb-9d7e-38bc5d83736e.png)
- Depending on your system, this takes some minutes to be handled by ganache. It can occur that ganache becomes unresponsive after those two commands
- Now check the contracts tab in ganache and make sure that there are at least 5 deployed contracts: **ChainOfCustodyToken, Control, LKGRegistry, Migrations, RBAC**

### Import flows for Smart Contracts to Node-RED
Now you need to import the flows for the Smart Contracts to your Node-RED installation:
- In Node-RED go to "Import" and import the ```flows.json```file from this repository. It's inside the flows folder
- Restart Node-RED and you're done
