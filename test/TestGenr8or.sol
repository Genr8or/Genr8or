pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Genr8or.sol";

contract TestGenr8or {

    uint public initialBalance = 10 ether;

    Genr8or genr8or = Genr8or(DeployedAddresses.Genr8or());

    function testBuyingThenSelling() public {
        Genr8 gen = genr8or.genr8("test", "test", 0x0, 18);
        assert(gen.myTokens() == 0);
        assert(gen.counterBalance() == 0);
        assert(gen.totalSupply() == 0 ether);
        gen.buy.value(1 ether)();
        assert(gen.counterBalance() == 1 ether);
        assert(gen.totalSupply() == 1 ether);
        assert(gen.myTokens() == 1 ether);
        gen.sell(1 ether);
        assert(gen.totalSupply() == 0 ether);
        assert(gen.myTokens() == 0 ether);
        assert(gen.counterBalance() == 0.1 ether);
    }

    function testBuyingThenTransferingBackToSell() public {
        Genr8 gen = genr8or.genr8("test2", "test2", 0x0, 18);
        assert(gen.myTokens() == 0);
        assert(gen.counterBalance() == 0);
        assert(gen.totalSupply() == 0 ether);
        gen.buy.value(1 ether)();
        assert(gen.counterBalance() == 1 ether);
        assert(gen.totalSupply() == 1 ether);
        assert(gen.myTokens() == 1 ether);
        gen.transfer(address(gen), 1 ether);
        assert(gen.myTokens() == 0 ether);
        assert(gen.totalSupply() == 0 ether);
        assert(gen.counterBalance() == 0.1 ether);
    }


    function () public payable {
        // This will NOT be executed when Ether is sent. \o/
    }

}