pragma solidity ~0.4.24;
import "./LeadHands.sol";

contract FairHands is LeadHands {
    constructor(uint256 myBondValue, uint256 myInflationMultipler, uint256 multiplierPercent, address sourceAddress, address secondSource, string name, string symbol, string tokenURI) public 
        LeadHands(myBondValue, myInflationMultipler, multiplierPercent, sourceAddress, secondSource, name, symbol, tokenURI){

    }
}