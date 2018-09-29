var FundingSecured = artifacts.require("FundingSecured");
var FoundersCards = artifacts.require("FoundersCards");
var LeadFunds = artifacts.require("LeadFunds");

module.exports = function(deployer) {
  deployer.deploy(FundingSecured).then(function(fundingSecured){
    deployer.deploy(FoundersCards, fundingSecured);
    deployer.deploy(LeadFunds, fundingSecured, 200);
  });
};