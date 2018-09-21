pragma solidity ^0.4.25;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "./Genr8or.sol";

// file name has to end with '_test.sol'
contract test_1 {
    
    function beforeAll () {
      // here should instanciate tested contract
      Genr8or factory = new Genr8or();
    }
    
    
    function checkCreate () public constant returns (bool) {
      Genr8or factory = new Genr8or();
      factory.genr8("test", "test", 0x0, 18);
      return true;
    }
}

contract test_2 {
   
    function beforeAll () {
      // here should instanciate tested contract
    }
    

    function check2 () public constant returns (bool) {
      // this function is constant, use the return value (true or false) to test the contract
      return true;
    }
}