var Genr8or = artifacts.require("Genr8or");
var Genr8 = artifacts.require("Genr8");

module.exports = function(deployer) {
  deployer.deploy(Genr8);
  deployer.deploy(Genr8or);
};