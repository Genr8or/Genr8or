var P3D = artifacts.require("P3D");
var IronHands = artifacts.require("IronHands");

module.exports = function(deployer) {
  deployer.deploy(P3D).then(function(instance){
    deployer.deploy(IronHands, 200, instance);
  });
};