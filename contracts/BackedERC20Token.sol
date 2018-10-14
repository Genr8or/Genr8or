pragma solidity 0.4.24;
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./MintableBurnableERC20Token.sol";

contract BackedERC20Token is MintableBurnableERC20Token {

    address counter;
    uint256 precision;

    constructor(string name, string symbol, uint8 decimals, address _counter, uint256 _precision) DetailedERC20(name, symbol, decimals) public {
        counter = _counter;
        precision = _precision;
    }

    function counterBalance() public view returns (uint256){
        if(counter == 0x0){
            return address(this).balance;
        }
        return ERC20(counter).balanceOf(this);
    }

    /**
     * Convert X tokens to Y counter
     */
    function tokensToCounter(uint256 anAmount) public view returns(uint256) {
        if(totalSupply() == 0){
            return anAmount;
        }
        return SafeMath.div(SafeMath.mul(SafeMath.div(SafeMath.mul(totalSupply(), precision), counterBalance()), anAmount),precision);
    }
    
    /**
     * Convert Y counter to X tokens
     */
    function counterToTokens(uint256 anAmount) public view returns(uint256) {
        if(totalSupply() == 0){
            return anAmount;
        }
        return SafeMath.div(SafeMath.mul(SafeMath.div(SafeMath.mul(counterBalance(), precision), totalSupply()), anAmount), precision);
    }

}