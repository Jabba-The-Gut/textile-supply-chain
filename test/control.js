const RBAC = artifacts.require("RBAC");
const CONTROL = artifacts.require("Control");
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
    let chance;
    let admin;
    let rbac;
    let owner;
    let control;
    var control_addresses = [];
    var supply_chain_addresses = [];
    var normal_addresses = [];

    "use strict";

    // deploy contracts used to test
    async function deployContracts() {
        let chance = new Chance();
        let admin = chance.pickone(accounts);
        let rbac = await RBAC.new({ from: admin });
        let owner = chance.pickone(accounts);
        let control = await CONTROL.new(rbac.address, { from: owner });
        console.debug(`New Control contract deployed - address: ${control.address}`);
        return [chance, admin, rbac, owner, control];
    }

    // setup environment before tests
    before(async () => {
        // deploy contracts
        [chance, admin, rbac, owner, control] = await deployContracts();

        // setup addresses
        control_addresses = accounts.slice(0, 3);
        supply_chain_addresses = accounts.slice(4, 7);
        normal_addresses = accounts.slice(8, 9);

        // assign roles to addresses
        control_addresses.forEach(address => {
            rbac.addMember(address, "CONTROL", { from: admin });
        });

        supply_chain_addresses.forEach(address => {
            rbac.addMember(address, "SUPPLY_CHAIN_ENTITY", { from: admin });
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
        await expectRevert(control.startControl(chance.pickone(supply_chain_addresses), { from: chance.pickone(normal_addresses) }), "Account is not a control instance.");
        await expectRevert.unspecified(control.startControl(chance.pickone(normal_addresses), { from: chance.pickone(control_addresses) }), "Account to be controlled is not a supply chain entity.");
    });

    it("happy path: check events and transitions", async () => {
        var controlled = chance.pickone(supply_chain_addresses);
        var controller = chance.pickone(control_addresses);

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
        var controlled = chance.pickone(supply_chain_addresses);
        var controller = chance.pickone(control_addresses);

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
        var controlled = chance.pickone(supply_chain_addresses);
        var controller = chance.pickone(control_addresses);
        var other_controller = chance.pickone(control_addresses);

        // make sure the control addresses are different
        while (controller == other_controller) {
            other_controller = chance.pickone(control_addresses);

        }

        // create control
        await control.startControl(controlled, { from: controller });

        await expectRevert(control.reportFindingsForControl(3, { gseOK: 1, findings: ["test"] }, { from: other_controller }), "Only the controller can add findings.")
    })

    it("check that only the controlled address can acknowledge a control they were controlled in", async () => {
        var controlled = chance.pickone(supply_chain_addresses);
        var controller = chance.pickone(control_addresses);
        var other_controlled = chance.pickone(supply_chain_addresses);

        // make sure the controlled addresses are different
        while (controlled == other_controlled) {
            other_controlled = chance.pickone(supply_chain_addresses);
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
        var controlled = chance.pickone(supply_chain_addresses);
        var controller = chance.pickone(control_addresses);

        await expectRevert(control.reportFindingsForControl(5, { gseOK: 1, findings: ["test"] }, { from: controller }), "No control with given ID.");
        await expectRevert(control.acknowledgeControl(5, 1, { from: controlled }), "No control with given ID.");
    })

});