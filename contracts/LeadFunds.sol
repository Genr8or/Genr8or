pragma solidity ^0.4.24;
import "./LeadHands.sol";

contract LeadFunds is LeadHands {
    constructor(uint256 multiplierPercent, address sourceAddress, address secondSource, string name, string symbol, string tokenURI) public 
        LeadHands(multiplierPercent, sourceAddress, secondSource, name, symbol, tokenURI){

    }
    
}