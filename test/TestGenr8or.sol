pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Genr8or.sol";

contract TestGenr8or {
    Genr8or genr8or = Genr8or(DeployedAddresses.Genr8or());

    function testGenr8or() public {

    }

}