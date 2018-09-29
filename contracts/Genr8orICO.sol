pragma solidity ^0.4.24;
import "./Genr8or.sol";
import "./Genr8.sol";
import "./Genr8ICO.sol";
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

contract Genr8orICO {

    event Create(bytes32 name,
        bytes32 symbol,
        address counter,
        uint8 decimals,
        uint256 launchBlockHeight,
        uint256 launchBalanceTarget,
        uint256 launchBalanceCap,
        address creator
    );

    Genr8or public genr8or;
    Genr8Registry public registry;
    mapping(bytes32 => Genr8ICO) public nameRegistry;

    constructor(address myGenr8or) public {
        genr8or = Genr8or(myGenr8or);
        registry = genr8or.registry;
    }

    function list() public view returns (Genr8ICO[]){
        return registry;
    }

    function lookUp(bytes32 name) public view returns (Genr8ICO){
        return nameRegistry[name];
    }

    function genr8ICO(        
        bytes32 name, // Name of the DivvyUp
        bytes32 symbol,  // ERC20 Symbol fo the DivvyUp
        address counter, // The counter currency to accept. Example: 0x0 for ETH, otherwise the ERC20 token address.
        uint8 decimals, // Number of decimals the token has. Example: 18
        uint256 launchBlockHeight, // Block this won't launch before, or 0 for any block.
        uint256 launchBalanceTarget, // Balance this wont launch before, or 0 for any balance. (soft cap)
        uint256 launchBalanceCap // Balance this will not exceed, or 0 for no cap. (hard cap)
        )
        public 
        returns (Genr8ICO)
    {
        require(address(genr8or.lookUp(name)) == 0x0 && address(lookUp(name)) == 0x0);
        Genr8ICO ico = new Genr8ICO(name, symbol, counter, decimals, launchBlockHeight, launchBalanceTarget, launchBalanceCap, genr8or);
        ico.transferOwnership(msg.sender);
        registry.push(ico);
        nameRegistry[name] = ico;
        emit Create(name, symbol, counter, decimals, launchBlockHeight, launchBalanceTarget, launchBalanceCap, msg.sender);        
        return ico;   
    }

}