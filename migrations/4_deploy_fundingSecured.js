var FundingSecured = artifacts.require("FundingSecured");
var FoundersCards = artifacts.require("FoundersCards");
var LeadHands = artifacts.require("LeadHands");

module.exports = function(deployer) {
  deployer.deploy(FundingSecured).then(function(fundingSecured){
    deployer.deploy(FoundersCards, fundingSecured);
    deployer.deploy(LeadHands, 200, fundingSecured, 0, "Lead Funds", "LEADFUNDS", "fundingsecured.me/LeadFunds/fund/");
  });
};