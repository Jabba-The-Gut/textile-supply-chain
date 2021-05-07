const RBAC = artifacts.require("RBAC");
const CONTROL = artifacts.require("Control");
const REGISTRY = artifacts.require("LKGRegistry");
const CONTROL_STAT_MACHINE = artifacts.require('ControlStateMachine');
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

contract("Control Test Suite", async accounts => {
    let chance_instance;
    let rbac_admin;
    let rbac;
    let registry;
    let control;
    var control_addresses = [];
    var supply_chain_addresses = [];
    var normal_addresses = [];

    "use strict";

    // deploy contracts used to test
    async function deployContracts() {
        let chance = new Chance();
        let rbac_admin_address = accounts[0];
        let rbac = await RBAC.new({ from: rbac_admin_address });
        let registry = await REGISTRY.new(rbac.address)
        let control = await CONTROL.new(rbac.address, registry.address);
        console.debug(`New Control contract deployed - address: ${control.address}`);
        return [chance, rbac_admin_address, rbac, registry, control];
    }

    // setup environment before tests
    before(async () => {
        // deploy contracts
        [chance_instance, rbac_admin, rbac, registry, control] = await deployContracts();

        // setup addresses
        control_addresses = accounts.slice(1, 3);
        supply_chain_addresses = accounts.slice(4, 7);
        normal_addresses = accounts.slice(8, 9);

        // add address of control contract to admin role ( so he can create registry entries)
        rbac.addMember(control.address, "ADMIN", {from: rbac_admin});

        // add supply chain admin role to rbac_admin so he can add entities to the registry
        rbac.addMember(rbac_admin, "ADMIN", {from: rbac_admin});

        // assign roles to addresses and add them to registry
        control_addresses.forEach(address => {
            rbac.addMember(address, "CONTROL", { from: rbac_admin });
            registry.addControlEntity(address, {role: 0, description: "tier 4", gseStatus: 0, numberOfControls: 0}, {from: rbac_admin});
        });

        supply_chain_addresses.forEach(address => {
            rbac.addMember(address, "SUPPLY_CHAIN_ENTITY", { from: rbac_admin });
            registry.addSupplyChainEntity(address, {role: 0, tier: "tier 4", gseStatus: 0, controls: [], transactions: []}, {from: rbac_admin});
        });

        const output = [];
        for (const acct of accounts) {
            await web3.eth.personal.unlockAccount(acct);
            await output.push([acct, await web3.eth.getBalance(acct)]);
        }

        console.debug(`The number of accounts : ${accounts.length}`);
        console.table(output);
    });

    
    it("check that only addresses with the control role can start a control and only supply chain entities can be controlled", async () => {
        await expectRevert(control.startControl(chance_instance.pickone(supply_chain_addresses), { from: chance_instance.pickone(normal_addresses) }), "Account is not a control instance.");
        await expectRevert(control.startControl(chance_instance.pickone(normal_addresses), { from: chance_instance.pickone(control_addresses) }), "Account to be controlled is not a supply chain entity.");
    });


    it("happy path: check events and transitions", async () => {
        var controlled = chance_instance.pickone(supply_chain_addresses);
        var controller = chance_instance.pickone(control_addresses);

        // create control
        let new_control = await control.startControl(controlled, { from: controller });
        // check that control created event is emitted
        await expectEvent(new_control, 'ControlCreated', { 1: controlled, 2: controller });

        // add findings to control
        let addFindings = await control.reportFindingsForControl(1, { gseOK: 1, findings: ["everything ok"] }, { from: controller });
        // check that findings reported event is emitted
        await expectEvent(addFindings, 'FindingsForControlReported');

        // comment findings
        let acknowledge = await control.acknowledgeControl(1, 1, { from: controlled });
        // check that findings reported event is emitted
        await expectEvent(acknowledge, 'ControlFinished');
    })

    
    it("check that methods cannot be called on finished control", async () => {
        var controlled = chance_instance.pickone(supply_chain_addresses);
        var controller = chance_instance.pickone(control_addresses);

        // create control
        await control.startControl(controlled, { from: controller });

        // add findings to control
        await control.reportFindingsForControl(2, { gseOK: 1, findings: ["test"] }, { from: controller });

        // comment findings
        await control.acknowledgeControl(2, 1, { from: controlled });

        // try to add findings and comment on control that was already finished
        await expectRevert(control.reportFindingsForControl(2, { gseOK: 1, findings: ["test"] }, { from: controller }), "Method not executable at this stage of the control process");

        // try to comment on control that was already finished
        await expectRevert(control.acknowledgeControl(2, 1, { from: controlled }), "Method not executable at this stage of the control process");
    })

     
    it("check only the control address can add findings to a control started by the address", async () => {
        var controlled = chance_instance.pickone(supply_chain_addresses);
        var controller = chance_instance.pickone(control_addresses);
        var other_controller = chance_instance.pickone(control_addresses);

        // make sure the control addresses are different
        while (controller == other_controller) {
            other_controller = chance_instance.pickone(control_addresses);

        }

        // create control
        await control.startControl(controlled, { from: controller });

        await expectRevert(control.reportFindingsForControl(3, { gseOK: 1, findings: ["test"] }, { from: other_controller }), "Only the controller can add findings.")
        // add findings to control
        let addFindings = await control.reportFindingsForControl(3, { gseOK: 1, findings: ["test"] }, { from: controller });
        // check that findings reported event is emitted
        await expectEvent(addFindings, 'FindingsForControlReported');
        // comment findings
        let acknowledge = await control.acknowledgeControl(3, 0, { from: controlled });
        // check that findings reported event is emitted
        await expectEvent(acknowledge, 'ControlFinished');
    })

    it("check that only the controlled address can acknowledge a control they were controlled in", async () => {
        var controlled = chance_instance.pickone(supply_chain_addresses);
        var controller = chance_instance.pickone(control_addresses);
        var other_controlled = chance_instance.pickone(supply_chain_addresses);

        // make sure the controlled addresses are different
        while (controlled == other_controlled) {
            other_controlled = chance_instance.pickone(supply_chain_addresses);
        }

        // create control
        await control.startControl(controlled, { from: controller });

        // add findings to control
        await control.reportFindingsForControl(4, { gseOK: 0, findings: ["test"] }, { from: controller });

        await expectRevert(control.acknowledgeControl(4, 1, { from: other_controlled }), "Only controlled entity can acknowledge.");

        // comment findings
        let acknowledge = await control.acknowledgeControl(4, 1, { from: controlled });
        // check that findings reported event is emitted
        await expectEvent(acknowledge, 'ControlFinished');
    })

    it("check that only existing controls can be addressed", async () => {
        var controlled = chance_instance.pickone(supply_chain_addresses);
        var controller = chance_instance.pickone(control_addresses);

        await expectRevert(control.reportFindingsForControl(5, { gseOK: 1, findings: ["test"] }, { from: controller }), "No control with given ID.");
        await expectRevert(control.acknowledgeControl(5, 1, { from: controlled }), "No control with given ID.");
    })
});