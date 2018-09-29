pragma solidity ^0.4.24;
import "./LeadHands.sol";

contract LeadFunds is LeadHands {
    constructor(uint256 multiplierPercent, address sourceAddress) public 
        LeadHands(multiplierPercent, sourceAddress, 0x0, "", "", ""){

    }
    
}