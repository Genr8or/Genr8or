pragma solidity ^0.4.24;
import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./ApproveAndCallFallBack.sol";


/**
 * @title Mintable Burnable ERC20 Token
 * @dev Simple ERC20 Token example, with mintable token creation and burnable token destruction
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
 
contract MintableBurnableERC20Token is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  event Burn(address indexed from, uint256 amount);
   
    function mint(address to, uint256 amount) internal returns (bool) {
        // prevent overflow
        assert(amount > 0 && (SafeMath.add(amount,totalSupply()) > totalSupply()));
        totalSupply_ = totalSupply_.add(amount);
        balances[to] = balances[to].add(amount);
        emit Mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) internal returns (bool) {
        require(balances[from] <= amount);
        totalSupply_ = totalSupply_.sub(amount);
        balances[from] = balances[from].sub(amount);
        emit Burn(from, amount);
        return true;
    }

        /**
    * Token owner can approve for `spender` to transferFrom(...) `tokens`
    * from the token owner's account. The `spender` contract function
    * `receiveApproval(...)` is then executed
    * 
    */
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

}