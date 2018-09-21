pragma solidity ^0.4.25;
import "./Owned.sol";
import "./Genr8.sol";

contract Genr8or is Owned {

    event Create(
        bytes32 name,
        bytes32 symbol,
        address counter,
        uint8 decimals,
        address creator
    );
  
    address[] public registry;

    function list() public view returns(address[]){
        return registry;
    }

    function genr8(
        bytes32 name, // Name of the Genr8 vertical
        bytes32 symbol,  // ERC20 Symbol fo the Genr8 vertical
        address counter, // The counter currency to accept. Example: 0x0 for ETH, otherwise the ERC20 token address.
        uint8 decimals // Number of decimals the token has. Example: 18 for ETH
     )
        public 
        returns(address)
    {
        Genr8 myGenr8 = new Genr8();
        myGenr8.setName(name);
        myGenr8.setSymbol(symbol);
        myGenr8.changeOwner(msg.sender);
        if(counter != 0x0){
            myGenr8.setCounter(counter);
            myGenr8.setDecimals(decimals);
        }
        registry.push(myGenr8);
        emit Create(name, symbol, counter, decimals, msg.sender);
        return myGenr8;
    }

    /**
    * Owner can transfer out any accidentally sent ERC20 tokens
    * 
    * Implementation taken from ERC20 reference
    * 
    */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}