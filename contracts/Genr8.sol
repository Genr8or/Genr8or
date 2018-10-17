pragma solidity ^0.4.24;
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./Percent.sol";
import "./BackedERC20Token.sol";

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
contract Genr8 is Ownable, BackedERC20Token {
    using SafeMath for uint256;
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }
    
    modifier onlyPreLaunch() {
        require(totalSupply() == 0 && counterBalance() == 0);
        _;
    }

    modifier ethCounter() {
        require(counter == 0x0);
        _;
    }

    modifier erc20Counter(){
        require(counter != 0x0);
        _;
    }

    modifier validInvestment(uint256 amount){
        require(amount >= MIN_BUY);
        _;
    }
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    event Buy(
        address indexed customerAddress,
        uint256 incomingCounter,
        uint256 tokensMinted
    );
    
    event Sell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 counterEarned
    );


    event Revenue(
        uint256 amount,
        address source,
        string reason
    );
    
    /*=====================================
    =              CONSTANTS              =
    =====================================*/
    
    uint256 constant MIN_BUY = 0.0001 ether;
        
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /**
    * -- APPLICATION ENTRY POINTS --  
    */
    constructor(string myName, string mySymbol, uint8 myDecimals, address myCounter, uint256 myPrecision) public BackedERC20Token(myName, mySymbol, myDecimals, myCounter, myPrecision) {
    }

    /**
     * Converts all incoming counter to tokens for the caller
     */
    function invest() public payable ethCounter validInvestment(msg.value) returns(uint256) {
        require(msg.value > MIN_BUY);
        return purchaseTokens(msg.sender, msg.value);
    }
    

    /**
     * Converts all incoming counter to tokens for the caller
     */
    function investERC20(uint256 amount) public erc20Counter validInvestment(msg.value) returns(uint256) {
        require(ERC20(counter).transferFrom(msg.sender, this, amount));
        return purchaseTokens(msg.sender, amount);
    }


    /**
     * Fallback function to handle counter that was sent straight to the contract.
     * Causes tokens to be purchased.
     */
    function() payable public {
        emit Revenue(msg.value, msg.sender, "ETH Deposit");
    }
    
    /**
     * Create revenue without purchasing tokens
     */
    function donate() payable public {
        emit Revenue(msg.value, msg.sender, "ETH Donation");
    }
    
    /**
     * Liquifies tokens to counter.
     */
    function sell(uint256 amountOfTokens) onlyTokenHolders public returns(uint256) {
        return sellTokens(msg.sender, amountOfTokens);
    }

    /**
     * Transfer tokens from the caller to a new holder.
     * Transfering ownership of tokens requires settling outstanding dividends
     * and transfering them back. You can therefore send 0 tokens to this contract to
     * trigger your withdraw.
     */
    function transfer(address toAddress, uint256 amountOfTokens) onlyTokenHolders public returns(bool) {
       // Sell on transfer in instead of transfering to us
        if(toAddress == address(this)){
            // If we sent in tokens
            if(amountOfTokens > 0){
                //destroy them and credit their account with ETH
                sellTokens(msg.sender, amountOfTokens);
            }
            //Don't need to do anything else.
            return true;
        }
        //Do the normal transfer instead
        return super.transfer(toAddress, amountOfTokens);
    }
 

    /*----------  HELPERS AND CALCULATORS  ----------*/

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
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(address who, uint256 incomingCounter) internal returns(uint256) {
        uint256 amountOfTokens = counterToTokens(incomingCounter);
        mint(who, amountOfTokens);
        emit Buy(who, incomingCounter, amountOfTokens);
        emit Transfer(0x0, who, amountOfTokens);
        return amountOfTokens;
    }

    function sellTokens(address who, uint256 tokenAmount) internal returns(uint256) {
        require(tokenAmount > 0);
        require(tokenAmount <= balanceOf(who));
        uint256 counterAmount = tokensToCounter(tokenAmount);
        burn(who, tokenAmount);
        //Send them their eth/counter
        if(counter == 0x0){
            who.transfer(counterAmount);
        }else{
            ERC20(counter).transfer(who, counterAmount);
        }
        
        // fire event
        emit Sell(who, tokenAmount, counterAmount);
        emit Transfer(who, 0x0, tokenAmount);
        return counterAmount;
    }

    /**
    * Owner can transfer out any accidentally sent ERC20 tokens
    * 
    * Implementation taken from ERC20 reference
    * 
    */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        require(tokenAddress != counter);
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
}