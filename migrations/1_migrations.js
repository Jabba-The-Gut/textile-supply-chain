const Migrations = artifacts.require('Migrations');
const RBAC = artifacts.require('RBAC');
const Control = artifacts.require('Control');
const Registry = artifacts.require('LKGRegistry');

module.exports = function (deployer) {
  deployer.deploy(Migrations);

  // then necessary because otherwise it's a race condition
  deployer.deploy(RBAC).then(function() {
    return deployer.deploy(Registry, RBAC.address).then(function() {
      return deployer.deploy(Control, RBAC.address, Registry.address);
    });

  });
};
