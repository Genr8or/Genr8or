var FundingSecured = artifacts.require("FundingSecured");
var FoundersCards = artifacts.require("FoundersCards");
var LeadFunds = artifacts.require("LeadFunds");

module.exports = function(deployer) {
  deployer.deploy(FundingSecured).then((fundingSecured) => {
    return deployer.deploy(LeadFunds, 200, fundingSecured.address).then(()=>{
        return deployer.deploy(FoundersCards, fundingSecured.address);
    });
  });
};