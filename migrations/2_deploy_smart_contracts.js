const rbac = artifacts.require('RBAC');
const control = artifacts.require('Control');

module.exports = function(deployer) {
  //deployer.deploy(rbac);
  //deployer.deploy(control, rbac.address);
  deployer.deploy(rbac).then(function(){
    deployer.deploy(control, rbac.address)});
};