const RBAC = artifacts.require("RBAC");
const REGISTRY = artifacts.require("LKGRegistry");
const SupplyChainToken = artifacts.require("SupplyChainNFT")
const Chance = require('chance');
const toBN = web3.utils.toBN;
const { constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const truffleAssert = require('truffle-assertions');



//References
//Truffle test in JavaScript : https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
//Truffle Contract Guide : https://www.trufflesuite.com/docs/truffle/getting-started/interacting-with-your-contracts
//Truffle Contract Package : https://github.com/trufflesuite/truffle/tree/master/packages/contract
//Mocha Documentation : https://mochajs.org/#getting-started
//Chai Assert API : https://www.chaijs.com/api/assert/
//Chai Expect/Should API : https://www.chaijs.com/api/bdd/
//OpenZeppelin Test Helpers API : https://docs.openzeppelin.com/test-helpers/0.5/api
//web3 API : https://web3js.readthedocs.io/en/v1.2.11/
//chance.js : https://chancejs.com/
//bn.js : https://github.com/indutny/bn.js/
//JavaScript Reference (MDN) : https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference
//The Modern JavaScript Tutorial : http://javascript.info/

contract("Registry Test Suite", async accounts => {
    let chance_instance;
    let rbac_admin;
    let rbac;
    let registry;
    var control_addresses = [];
    var supply_chain_addresses = [];

    "use strict";

    // deploy contracts used to test
    async function deployContracts() {
        let chance = new Chance();
        let rbac_admin_address = accounts[0];
        let rbac = await RBAC.new({ from: rbac_admin_address });
        let registry = await REGISTRY.new(rbac.address)
        return [chance, rbac_admin_address, rbac, registry];
    }

    // setup environment before tests
    before(async () => {
        // deploy contracts
        [chance_instance, rbac_admin, rbac, registry, owner_of_token_contract, cotton_token] = await deployContracts();

        // setup addresses
        control_addresses = accounts.slice(1, 3);
        supply_chain_addresses = accounts.slice(3, 8);
        normal_addresses = accounts.slice(8, 9);

        // add supply chain admin role to rbac_admin so he can add entities to the registry
        rbac.addMember(rbac_admin, "ADMIN", {from: rbac_admin});

        // assign roles to addresses and add them to registry
        control_addresses.forEach(address => {
            rbac.addMember(address, "CONTROL", { from: rbac_admin });
        });

        supply_chain_addresses.forEach(address => {
            rbac.addMember(address, "SUPPLY_CHAIN_ENTITY", { from: rbac_admin });
        });

        const output = [];
        for (const acct of accounts) {
            await web3.eth.personal.unlockAccount(acct);
            await output.push([acct, await web3.eth.getBalance(acct)]);
        }

        console.debug(`The number of accounts : ${accounts.length}`);
        console.table(output);
    });

    
    it("Add a supply chain entity, get it and then remove it again", async () => {
        let entity = chance_instance.pickone(supply_chain_addresses);

        await registry.addSupplyChainEntity(entity, {role: 1, tier: "tier 0", gseStatus: 0, controls: [], transactions:[]}, {from:rbac_admin});

        assert.isNotEmpty(await registry.getSupplyChainEntity(entity, {from: entity}));
        
        await registry.removeSupplyChainEntity(entity, {from: rbac_admin});

        await expectRevert(registry.getSupplyChainEntity(entity, {from: entity}), "Entity does not exist");
    });

    it("Add a control entity, get it and then remove it again", async () => {
        let entity = chance_instance.pickone(control_addresses);

        await registry.addControlEntity(entity, {role: 1, description: "test", gseStatus: 0, numberOfControls: 0}, {from:rbac_admin});

        assert.isNotEmpty(await registry.getControlentity(entity, {from: entity}));
        
        await registry.removeControlEntity(entity, {from: rbac_admin});

        await expectRevert(registry.getControlentity(entity, {from: entity}), "Entity does not exist");
    });

    it("Add a control to an existing supply chain entity", async () => {
        let entity = chance_instance.pickone(supply_chain_addresses);
        let control_entity = chance_instance.pickone(control_addresses);

        await registry.addSupplyChainEntity(entity, {role: 1, tier: "tier 0", gseStatus: 0, controls: [], transactions:[]}, {from:rbac_admin});
        await registry.addControlEntity(control_entity, {role: 1, description: "test", gseStatus: 0, numberOfControls: 0}, {from:rbac_admin});

        await registry.addControl(entity, {controlId: 1, timeOfControl: 2345, status: 0, controlled: entity, controller:control_entity }, {from: rbac_admin});        
        
        // get the supply and control entity
        let supply_chain_struct = await registry.getSupplyChainEntity(entity, {from: entity});
        let control_entity_struct = await registry.getControlentity(control_entity, {from: control_entity});

        // make sure that the control was added to the supply chain entity and the control entities counter
        // was increased
        assert.isNotEmpty(supply_chain_struct.controls[0]);
        assert.equal(control_entity_struct.numberOfControls, 1);

        await registry.removeSupplyChainEntity(entity, {from: rbac_admin});
        await registry.removeControlEntity(control_entity, {from: rbac_admin});
    });


    it("Add a nonGSE transaction to an existing supply chain entity", async () => {
        let entity = chance_instance.pickone(supply_chain_addresses);

        await registry.addSupplyChainEntity(entity, {role: 1, tier: "tier 0", gseStatus: 0, controls: [], transactions:[]}, {from:rbac_admin});

        await registry.addNonGSETransaction(entity, {time: 2234, tokenId: 1}, {from: rbac_admin});        
        
        // get the supply and control entity
        let supply_chain_struct = await registry.getSupplyChainEntity(entity, {from: entity});

        // make sure that the transaction was added to the supply chain entity
        assert.isNotEmpty(supply_chain_struct.transactions[0]);

        await registry.removeSupplyChainEntity(entity, {from: rbac_admin});
    });

    it("Add multiple controls and nonGSE Transactions to an existing supply chain entity", async () => {
        let control_entity = chance_instance.pickone(control_addresses);

        supply_chain_addresses.forEach(supply_chain_addresses => {
            registry.addSupplyChainEntity(supply_chain_addresses, {role: 0, tier: "tier 4", gseStatus: 0, controls: [], transactions: []}, {from: rbac_admin});
        });

        control_addresses.forEach(control_addresses => {
            registry.addControlEntity(control_addresses, {role: 0, description: "tier 4", gseStatus: 0, numberOfControls: 0}, {from: rbac_admin});
        });

        for(entity of supply_chain_addresses) {
            for (i = 0; i < 5; i++) {
                await registry.addControl(entity, {controlId: i, timeOfControl: 2345, status: 0, controlled: entity, controller:control_entity }, {from: rbac_admin});    
                await registry.addNonGSETransaction(entity, {time: 2234, tokenId: i}, {from: rbac_admin});        
              }
        };
        
        for(entity of supply_chain_addresses) {
            let nonGSETransactions = await registry.getNonGSETransactions(entity, {from: entity});
            assert.isArray(nonGSETransactions);
            assert.equal(nonGSETransactions.length, 5);
        };

        for(entity of supply_chain_addresses) {
            let controls = await registry.getControls(entity, {from: entity});
            assert.isArray(controls);
            assert.equal(controls.length, 5);
        };

        for(entity of supply_chain_addresses) {
            let controls = await registry.getControls(entity, {from: entity});
            for (i = 0; i < controls.length; i++) {
                let control = await registry.getControl(controls[i],{from: entity});
                assert.isArray(control);
                assert.isNotEmpty(control);
            }
        };

        for(entity of supply_chain_addresses) {
            let nonGSETransactions = await registry.getNonGSETransactions(entity, {from: entity});
            for (i = 0; i < nonGSETransactions.length; i++) {
                let transaction = await registry.getNonGSETransaction(nonGSETransactions[i], {from: entity});
                assert.isArray(transaction);
                assert.isNotEmpty(transaction);
            }
        };

        // check that all controls were recorded at the given control entity
        let control_entity_struct = await registry.getControlentity(control_entity, {from: control_entity});
        assert.equal(control_entity_struct[3], 25);
    });
});