pragma solidity ^0.4.24;
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Genr8.sol";
import "./Genr8Registry.sol";

/*
* Sensei Kevlar presents...
*
* ====================================================================*
*                                             ,---.-,    
*                                            '   ,'  '.  
*  ,----..                                  /   /      \ 
* /   /   \                                .   ;  ,/.  : 
*|   :     :                ,---,   __  ,-.'   |  | :  ; 
*.   |  ;. /            ,-+-. /  |,' ,'/ /|'   |  ./   : 
*.   ; /--`     ,---.  ,--.'|'   |'  | |' ||   :       , 
*;   | ;  __   /     \|   |  ,"' ||  |   ,' \   \     /  
*|   : |.' .' /    /  |   | /  | |'  :  /    ;   ,   '\  
*.   | '_.' :.    ' / |   | |  | ||  | '    /   /      \ 
*'   ; : \  |'   ;   /|   | |  |/ ;  : |   .   ;  ,/.  : 
*'   | '/  .''   |  / |   | |--'  |  , ;   '   |  | :  ; 
*|   :    /  |   :    |   |/       ---'    '   |  ./   : 
* \   \ .'    \   \  /'---'                |   :      /  
*  `---`       `----'                       \   \   .'   
*                                            `---`-'     
* 
* =====================================================================*
*
*
*/

contract Genr8or is Ownable {

    event Create(
        bytes32 name,
        bytes32 symbol,
        uint256 sellRevenuePercent,
        address counter,
        uint8 decimals,
        address creator
    );
  
    Genr8Registry public registry;

    constructor(Genr8Registry myRegistry) public {
        registry = myRegistry;
    }


    function lookUp(bytes32 name) public view returns(Genr8){
        return Genr8(registry.lookUp(name, "Genr8"));
    }

    function genr8(
        bytes32 name, // Name of the Genr8 vertical
        bytes32 symbol,  // ERC20 Symbol fo the Genr8 vertical
        uint256 sellRevenuePercent, //Percent taken for revenue on sells, 0 for none
        address counter, // The counter currency to accept. Example: 0x0 for ETH, otherwise the ERC20 token address.
        uint8 decimals // Number of decimals the token has. Example: 18 for ETH
     ) public returns(Genr8) {
        address existing = registry.lookUp(name, "Genr8");
        address existingICO = registry.lookUp(name, "Genr8ICO");
        require(existing == 0x0);
        require(existingICO == 0x0 || existingICO == msg.sender);
        Genr8 myGenr8 = new Genr8(name, symbol, sellRevenuePercent, counter, decimals);
        myGenr8.transferOwnership(msg.sender);
        registry.setRegistry(name, "Genr8", myGenr8);
        emit Create(name, symbol, sellRevenuePercent, counter, decimals, msg.sender);
        return myGenr8;
    }

    /**
    * Owner can transfer out any accidentally sent ERC20 tokens
    * 
    * Implementation taken from ERC20 reference
    * 
    */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
}