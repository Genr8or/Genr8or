pragma solidity 0.4.24;
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./MintableBurnableERC20Token.sol";

contract BackedERC20Token is MintableBurnableERC20Token {

    address public counter;
    uint256 public precision;

    /**
     * Public constructor that requires all arguments are specified.
     */
    constructor(string name, string symbol, uint8 decimals, address _counter, uint256 _precision) MintableBurnableERC20Token(name, symbol, decimals) public {
        counter = _counter;
        precision = _precision;
    }

    /**
     * The counter is the backing token's ERC20 address, or 0x0 to use ETH.
     */
    function counter() public view returns (address){
        return counter;
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

    /**
     * Method to view the current counter balance of the contract
     */
    function counterBalance() public view returns(uint256) {
        if(counter == 0x0){
            return address(this).balance;
        } else {
            return ERC20(counter).balanceOf(this);
        }
    }
    
    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens() public view returns(uint256) {
        return balanceOf(msg.sender);
    }

}