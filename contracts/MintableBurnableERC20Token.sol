pragma solidity ^0.4.24;
import "./StandardToken.sol";
import "./Ownable.sol";

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
 
contract MintableBurnableERC20Token is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  event Burn(address indexed from, uint256 amount);
   
    function mint(address to, uint256 amount) internal returns (bool) {
        // prevent overflow
        assert(amount > 0 && (SafeMath.add(amount,totalSupply) > totalSupply));
        totalSupply = totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
        emit Mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) internal returns (bool) {
        require(balances[from] <= amount);
        totalSupply = totalSupply.sub(amount);
        balances[from] = balances[from].sub(amount);
        emit Burn(from, amount);
        return true;
    }

}