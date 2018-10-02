pragma solidity ^0.4.24;
import "./Genr8or.sol";
import "./Genr8ICO.sol";
import "./Genr8RegistryInterface.sol";
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

contract Genr8orICO {

    event Create(bytes32 name,
        bytes32 symbol,
        uint256 sellRevenuePercent,
        address counter,
        uint8 decimals,
        uint256 launchBlockHeight,
        uint256 launchBalanceTarget,
        uint256 launchBalanceCap,
        address creator
    );

    Genr8or public genr8or;
    Genr8RegistryInterface public registry;
    mapping(bytes32 => Genr8ICO) public nameRegistry;

    constructor(address myGenr8or, address myRegistry) public {
        genr8or = Genr8or(myGenr8or);
        registry = Genr8RegistryInterface(myRegistry);
        //registry = genr8or.registry;
    }

    //function list() public view returns (Genr8ICO[]){
        //return registry;
    //}

    function lookUp(bytes32 name) public view returns (Genr8ICO){
        return Genr8ICO(registry.lookUp(name, "Genr8ICO"));
    }

    function genr8ICO(        
        bytes32 name, // Name of the DivvyUp
        bytes32 symbol,  // ERC20 Symbol fo the DivvyUp
        uint256 sellRevenuePercent, //The revenue taken as a percentage on sells, 0
        address counter, // The counter currency to accept. Example: 0x0 for ETH, otherwise the ERC20 token address.
        uint8 decimals, // Number of decimals the token has. Example: 18
        uint256 launchBlockHeight, // Block this won't launch before, or 0 for any block.
        uint256 launchBalanceTarget, // Balance this wont launch before, or 0 for any balance. (soft cap)
        uint256 launchBalanceCap // Balance this will not exceed, or 0 for no cap. (hard cap)
        )
        public 
        returns (Genr8ICO)
    {
        require(registry.lookUp(name, "Genr8") == 0x0 && registry.lookUp(name, "Genr8ICO") == 0x0);
        Genr8ICO ico = new Genr8ICO(name, symbol, sellRevenuePercent, counter, decimals, launchBlockHeight, launchBalanceTarget, launchBalanceCap, genr8or);
        ico.transferOwnership(msg.sender);
        registry.setRegistry(name, "Genr8ICO", ico);
        emit Create(name, symbol, sellRevenuePercent, counter, decimals, launchBlockHeight, launchBalanceTarget, launchBalanceCap, msg.sender);        
        return ico;   
    }

}