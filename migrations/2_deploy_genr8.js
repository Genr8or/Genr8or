var Genr8or = artifacts.require("Genr8or");
var Genr8 = artifacts.require("Genr8");
var Genr8ICO = artifacts.require("Genr8ICO");
var Genr8orICO = artifacts.require("Genr8orICO");
var Genr8Registry = artifacts.require("Genr8Registry");

module.exports = function(deployer) {
  return deployer.deploy(Genr8Registry).then((registry)=>{
    return deployer.deploy(Genr8, 0, 0, 10, 0, 18).then((genr8)=>{
      return deployer.deploy(Genr8or, registry.address).then((genr8or)=>{
        return deployer.deploy(Genr8ICO, 0, 0, 10, 0, 18, 0, 0, 0, 0).then((genr8ICO)=>{
          return deployer.deploy(Genr8orICO, genr8or.address, registry.address).then(async (genr8orICO)=>{
            console.log("Whitelisting the following addresses in the registry: [" + genr8or.address + ", " + genr8orICO.address + "]");
            await registry.setWhitelist(genr8or.address, true);
            await registry.setWhitelist(genr8orICO.address, true);
          });
        });
      });
    });
  });
};