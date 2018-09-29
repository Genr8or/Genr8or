var Hourglass = artifacts.require("Hourglass");
var IronHands = artifacts.require("IronHands");
var LeadHands = artifacts.require("LeadHands");

module.exports = function(deployer) {
  return deployer.deploy(Hourglass).then((hourglass) => {
    return deployer.deploy(IronHands, 200, hourglass.address).then((ironHands) => {
      return deployer.deploy(LeadHands, 200, hourglass.address, ironHands.address, "LeadHands", "LHS", "doublr.io/lhs/");
    });
  });
};