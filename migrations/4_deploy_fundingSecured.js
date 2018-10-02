var FundingSecured = artifacts.require("FundingSecured");
var FoundersCards = artifacts.require("FoundersCards");
var LeadFunds = artifacts.require("LeadFunds");

module.exports = function(deployer, network) {
    if(network == "live"){
        return deployer.deploy(LeadFunds, 200, 0x7e0529eb456a7c806b5fe7b3d69a805339a06180, 0x0, "LeadFunds", "LFS", "fundingsecured.me/lfs/");
    }else{
        return deployer.deploy(FundingSecured).then((fundingSecured) => {
            return deployer.deploy(LeadFunds, 200, fundingSecured.address, 0x0, "LeadFunds", "LFS", "fundingsecured.me/lfs/").then(()=>{
                return deployer.deploy(FoundersCards, fundingSecured.address);
            });
        });
    }
};