var Hourglass = artifacts.require("Hourglass");
var IronHands = artifacts.require("IronHands");
var IronHands = artifacts.require("LeadHands");

module.exports = function(deployer) {
  deployer.deploy(Hourglass).then(function(instance){
    deployer.deploy(IronHands, 200, instance).then(function(ironHands){
      deployer.deploy(LeadHands, 200, instance, ironHands, "LeadHands", "LHS", "www.example.com/lhs/");
    });
  });
};