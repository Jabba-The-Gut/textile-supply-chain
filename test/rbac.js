const RBAC = artifacts.require("RBAC");
const Chance = require('chance');
const toBN = web3.utils.toBN;
const { constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');


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

contract("Role Based Access Test Suite", async accounts => {

    "use strict";

    before(async () => {
        const output = [];
        for (const acct of accounts) {
            await web3.eth.personal.unlockAccount(acct);
            await output.push([acct, await web3.eth.getBalance(acct)]);
        }

        console.debug(`The number of accounts : ${accounts.length}`);
        console.table(output);
    });

    async function createFixtures() {
        const chance = new Chance();
        const admin = chance.pickone(accounts);
        const rbac = await RBAC.new({ from: admin });
        console.debug(`New RBAC contract deployed - address: ${rbac.address}`);
        return [chance, admin, rbac];
    }


    it("check that initial roles are present", async () => {
        const [chance, admin, rbac] = await createFixtures();

        assert.isTrue((await rbac.roleExists("ROOT")), "ROOT_ROLE not present");
        assert.isTrue((await rbac.roleExists("CONTROL")), "CONTROL_ROLE not present");
        assert.isTrue((await rbac.roleExists("SUPPLY_CHAIN_ENTITY")), "SUPPLY_CHAIN_ENTITY_ROLE not present");
    });

    it("check that the deployer has the admin role", async () => {
        const [chance, admin, rbac] = await createFixtures();

        assert.isTrue((await rbac.hasRole(admin, "ROOT")), "Contract Deployer should have ROOT_ROLE");
    });

    it("check that address with admin role can add new members to roles", async () => {
        const [chance, admin, rbac] = await createFixtures();

        // add random member to a role
        const random_member = chance.pickone(accounts);
        await rbac.addMember(random_member, "CONTROL", { from: admin });
        assert.isTrue((await rbac.hasRole(random_member, "CONTROL")), "Admin should be able to add new member to role");
    });

    it("check that address without an admin role cannot add new members to roles", async () => {
        const [chance, admin, rbac] = await createFixtures();

        // select random member and try to add them to a role from the random member address
        const random_member = chance.pickone(accounts);
        await expectRevert.unspecified(rbac.addMember(random_member, "CONTROL", { from: random_member }));
    });

    it("add member to address, check that he has the role, then remove him and check that he lost he role", async () => {
        const [chance, admin, rbac] = await createFixtures();

        // select random member 
        const random_member = chance.pickone(accounts);
        // ad the member to the role
        await rbac.addMember(random_member, "SUPPLY_CHAIN_ENTITY", { from: admin });
        assert.isTrue(await rbac.hasRole(random_member, "SUPPLY_CHAIN_ENTITY"));
        // remove from the role
        await rbac.removeMember(random_member, "SUPPLY_CHAIN_ENTITY", { from: admin });
        assert.isFalse(await rbac.hasRole(random_member, "SUPPLY_CHAIN_ENTITY"));
    });
});