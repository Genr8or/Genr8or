pragma solidity ^0.4.24;
import "./BackedERC20Token.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Genr8or.sol";

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

contract Genr8ICO is Ownable, BackedERC20Token {
    using SafeMath for uint256;
   
    modifier ethCounter(){
        require(counter == 0x0);
        _;
    }
    
    modifier erc20Counter(){
        require(counter != 0x0);
        _;
    }
   
    modifier hasNotLaunched(){
        require(!hasLaunched);
        _;
    }

    modifier hasAlreadyLaunched(){
        require(hasLaunched);
        _;
    }

    modifier isReadyToLaunch(){
        require((block.number >= launchBlockHeight || launchBlockHeight == 0) && (address(this).balance >= launchBalanceTarget));
        _;
    }

    modifier isUnderLaunchBalanceCap(uint256 newAmount){
        if(launchBalanceCap > 0){
            if(counter == 0x0){
                require(address(this).balance + newAmount <= launchBalanceCap);
            }else{
                require(ERC20(counter).balanceOf(this) + newAmount <= launchBalanceCap);
            }
        }
        _;
    }

    modifier balanceHolder(){
        require(balanceOf(msg.sender) > 0);
        _;
    }

    uint256 public launchBlockHeight = 0;
    uint256 public launchBalanceTarget = 0;
    uint256 public launchBalanceCap = 0;
    bool public hasLaunched = false;

    Genr8 public destination;
    Genr8or public factory;
    
    constructor(string aName, 
    string aSymbol, 
    uint8 someDecimals, 
    address aCounter, 
    uint256 aPrecision, 
    uint256 aLaunchBlockHeight, 
    uint256 aLaunchBalanceTarget, 
    uint256 aLaunchBalanceCap, 
    Genr8or aFactory)
    BackedERC20Token(aName, aSymbol, someDecimals, aCounter, aPrecision) 
    public {
        launchBlockHeight = aLaunchBlockHeight;
        launchBalanceTarget = aLaunchBalanceTarget;
        launchBalanceCap = aLaunchBalanceCap;
        factory = aFactory;
    }

    function() public payable {
        deposit();
    }

    function deposit() ethCounter isUnderLaunchBalanceCap(msg.value) public payable {
        if(msg.value == 0 && hasLaunched){
            withdraw(balanceOf(msg.sender));
            return;
        }
        require(!hasLaunched);
        mint(msg.sender, msg.value);
    }

    function depositERC20(uint256 amount) erc20Counter isUnderLaunchBalanceCap(amount) public {
        if(amount == 0 && hasLaunched){
            withdraw(balanceOf(msg.sender));
            return;
        }
        require(!hasLaunched);
        require(ERC20(counter).transferFrom(msg.sender, this, amount));
        mint(msg.sender, amount);
    }

    function launch() public hasNotLaunched isReadyToLaunch returns (address) {
        hasLaunched = true;
        destination = factory.genr8(name, symbol, decimals, counter, precision);
        Ownable(destination).transferOwnership(owner);
        if(totalSupply() > 0){
            if(counter == 0x0){
                destination.invest.value(totalSupply())();
            } else {
                destination.investERC20(totalSupply());
            }
        }
        counter = destination;
    }
    
    function withdraw(uint256 amount) balanceHolder public returns (bool) {
        require(balanceOf(msg.sender) <= amount);
        burn(msg.sender, amount);
        if(hasLaunched){
            uint256 withdrawAmount = tokensToCounter(amount);
            require(destination.transfer(msg.sender, withdrawAmount));
        }else{
            if(counter == 0x0){
                msg.sender.transfer(amount);
            } else{
                require(ERC20(counter).transfer(msg.sender, amount));
            }
        }
        return true;
    }

    function exit() balanceHolder public {
        withdraw(balanceOf(msg.sender));
    }
    
    /**
    * Owner can transfer out any accidentally sent ERC20 tokens
    * 
    * Implementation taken from ERC20 reference
    * 
    */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        // Do not allow the owner to prematurely steal tokens that do not belong to them
        if(!hasLaunched){
            require(tokenAddress != counter);
        }else{
            require(tokenAddress != address(destination));
        }
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

}