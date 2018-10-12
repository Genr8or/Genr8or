var Hourglass = artifacts.require("Hourglass");
var IronHands = artifacts.require("IronHands");
var LeadHands = artifacts.require("LeadHands");
var Sacrific3d = artifacts.require("Sacrific3d");

module.exports = function(deployer, network) {
  if(network == "live"){
    return deployer.deploy(LeadHands, 200, 0xb3775fb83f7d12a36e0475abdd1fca35c091efbe, 0xe58b65d1c0c8e8b2a0e3a3acec633271531084ed);
  }else{
    return deployer.deploy(Hourglass).then((hourglass) => {
      return deployer.deploy(IronHands, 200, hourglass.address).then((ironHands) => {
        return deployer.deploy(LeadHands, web3.toWei(.5,"ether"), 10, 200, hourglass.address, ironHands.address, "LeadHands", "LHS", "doublr.io/lh/").then((leadHands) => {
          //return deployer.deploy(Sacrific3d, hourglass.address, 1000000000000000, 5, 100000000000000000);
        });
      });
    });
  }
};