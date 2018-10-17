var FairExchange = artifacts.require("FairExchange");
var FairHands = artifacts.require("FairHands");

module.exports = function(deployer, network) {
    if(network == "live"){
        return deployer.deploy(FairExchange, web3.toWei(1,"ether"), 0, 200, 0xdE2b11b71AD892Ac3e47ce99D107788d65fE764e, 0x0, "FairLeadHands", "FLH", "fairdapp.com/flh/");
    }else{
        return deployer.deploy(FairExchange).then((fundingSecured) => {
            return deployer.deploy(FairHands, web3.toWei(1,"ether"), 0, 200, fundingSecured.address, 0x0, "FairLeadHands", "FLH", "fairdapp.com/flh/");
        });
    }
};