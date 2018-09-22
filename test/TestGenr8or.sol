pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Genr8or.sol";

contract TestGenr8or {

    uint public initialBalance = 1 ether;

    Genr8or genr8or = Genr8or(DeployedAddresses.Genr8or());

    function testGenr8or() public {
        Genr8 gen = genr8or.genr8("test", "test", 0x0, 18);
        assert(gen.myTokens() == 0);
        assert(gen.counterBalance() == 0);
        gen.buy.value(1 ether)();
        assert(gen.counterBalance() == 1 ether);
        assert(gen.totalTokens() == 1 ether);
        assert(gen.myTokens() == 1 ether);
        gen.sell(1 ether);
        assert(gen.myTokens() == 0 ether);
        assert(gen.totalTokens() == 0 ether);
        assert(gen.counterBalance() == 0.1 ether);
        

    }

    function () public payable {
    // This will NOT be executed when Ether is sent. \o/
  }

}