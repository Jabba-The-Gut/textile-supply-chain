const Migrations = artifacts.require('Migrations');
const RBAC = artifacts.require('RBAC');
const Control = artifacts.require('Control');
const Registry = artifacts.require('LKGRegistry');
const Token = artifacts.require("ChainOfCustodyToken");
let rbac_root_address;
let supply_chain_admin_address;
let producers;
let controllers;
let supply_chain_entities;

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(Migrations);

  // only deploy contracts if 20 accounts are available
  if (accounts.length == 20) {
    rbac_root_address = accounts[0];
    supply_chain_admin_address = accounts[1];
    producers = accounts.slice(2, 6);
    controllers = accounts.slice(6, 8);
    supply_chain_entities = accounts.slice(8, 19);


    // deploy the contracts
    await deployer.deploy(RBAC, { from: rbac_root_address });
    await deployer.deploy(Registry, RBAC.address, { from: supply_chain_admin_address });
    await deployer.deploy(Control, RBAC.address, Registry.address, { from: supply_chain_admin_address });
    await deployer.deploy(Token, "ChainOfCustodyToken", "COCT", Registry.address, RBAC.address);

    // get the deployed instances
    const rbac_contract = await RBAC.deployed();
    const registry_contract = await Registry.deployed();
    const control_contract = await Control.deployed();
    const token_contract = await Token.deployed();
    
    // setup role management
    await rbac_contract.addMember(rbac_root_address, "ADMIN", {from:rbac_root_address});
    await rbac_contract.addMember(rbac_root_address, "MINTER", {from:rbac_root_address});
    await rbac_contract.addMember(supply_chain_admin_address, "ADMIN", {from:rbac_root_address});

    for (let index = 0; index < producers.length; index++) {
      await rbac_contract.addMember(producers[index], "MINTER", {from: rbac_root_address});
      await rbac_contract.addMember(producers[index], "SUPPLY_CHAIN_ENTITY", {from: rbac_root_address});
    }

    for (let index = 0; index < controllers.length; index++) {
      await rbac_contract.addMember(controllers[index], "CONTROL", {from: rbac_root_address});
      await rbac_contract.addMember(controllers[index], "SUPPLY_CHAIN_ENTITY", {from: rbac_root_address});
    }

    for (let index = 0; index < supply_chain_entities.length; index++) {
      await rbac_contract.addMember(supply_chain_entities[index], "SUPPLY_CHAIN_ENTITY", {from: rbac_root_address});
    }
    
    await rbac_contract.addMember(token_contract.address, "ADMIN", {from:rbac_root_address});
    await rbac_contract.addMember(control_contract.address, "ADMIN", {from:rbac_root_address});

    // add the needed entities to the registry
    for (let index = 0; index < producers.length; index++) {
      await registry_contract.addSupplyChainEntity(producers[index], {role: 1, tier:"Tier " + (producers.length - index), gseStatus: 0, controls: [], transactions: []}, {from: supply_chain_admin_address});
    }

    for (let index = 0; index < controllers.length; index++) {
      await registry_contract.addControlEntity(controllers[index], {role: index, description: "Controlling Entity", gseStatus: 0, numberOfControls:0}, {from: supply_chain_admin_address});
    }

    for (let index = 0; index < supply_chain_entities.length; index++) {
      await registry_contract.addSupplyChainEntity(supply_chain_entities[index], {role: 0, tier:"Delivery instance " , gseStatus: 0, controls: [], transactions: []}, {from: supply_chain_admin_address});
    }
  }
}


