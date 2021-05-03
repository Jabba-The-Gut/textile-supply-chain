const rbac = artifacts.require('RBAC');


module.exports = function(deployer) {
  deployer.deploy(rbac);
};