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
        require(myTokens() > 0, "You must be an existing investor to do this.");
        _;
    }
    
    modifier ethCounter() {
        require(counter == 0x0, "This is configured for ERC-20, not ETH.");
        _;
    }

    modifier erc20Counter(){
        require(counter != 0x0, "This is configured for ETH, not ERC-20.");
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

        
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /**
    * -- APPLICATION ENTRY POINTS --  
    */
    constructor(string myName, string mySymbol, uint8 myDecimals, address myCounter, uint256 myPrecision) public BackedERC20Token(myName, mySymbol, myDecimals, myCounter, myPrecision) {
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
    function donate() payable public ethCounter {
        emit Revenue(msg.value, msg.sender, "ETH Donation");
    }
    
    /**
     * Converts all incoming counter to tokens for the caller
     */
    function invest() public payable ethCounter returns(uint256) {
        //They must send in more than 0 tokens
        require(msg.value > 0, "You must send ETH to invest.");
        //Mint the tokens for their investment
        return mintTokens(msg.sender, msg.value);
    }
    

    /**
     * Converts all incoming counter to tokens for the caller
     */
    function investERC20(uint256 amount) public erc20Counter returns(uint256) {
        //They must send in more than 0 tokens.
        require(amount > 0, "You must specificy an amount to invest.");
        //The transferFrom ERC20 should return true if the tokens were successfully transfered.
        require(ERC20(counter).transferFrom(msg.sender, this, amount), "The transfer was not suscesful.");
        //Mint the tokens for their investment
        return mintTokens(msg.sender, amount);
    }

    /**
     * Liquifies tokens to counter.
     */
    function divest(uint256 amountOfTokens) onlyTokenHolders public returns(uint256) {
        //They cannot divest 0 tokens.
        require(amountOfTokens > 0, "You cannot divest 0 tokens.");
        //The cannot transfer more than they own
        require(amountOfTokens <= balanceOf(msg.sender), "You cannot divest more tokens than you have.");
        //Do the sell
        return burnTokens(msg.sender, amountOfTokens);
    }

    /**
     * Transfer tokens from the caller to a new holder.
     */
    function transfer(address toAddress, uint256 amountOfTokens) onlyTokenHolders public returns(bool) {
        //The cannot transfer more than they own
        require(amountOfTokens <= balanceOf(msg.sender));
        // Sell on transfer in instead of transfering to us
        if(toAddress == address(this)){
            // If we sent in tokens
            if(amountOfTokens > 0){
                //destroy them and credit their account with ETH
                burnTokens(msg.sender, amountOfTokens);
            }
            //Don't need to do anything else.
            return true;
        }
        //Do the normal transfer instead
        return super.transfer(toAddress, amountOfTokens);
    }
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function mintTokens(address who, uint256 incomingCounter) internal returns(uint256) {
        //Compute the number of tokens to give them
        uint256 amountOfTokens = counterToTokens(incomingCounter);
        //Mint the new tokens
        mint(who, amountOfTokens);
        //fire events
        emit Buy(who, incomingCounter, amountOfTokens);
        emit Transfer(0x0, who, amountOfTokens);
        //Return the amount of tokens minted
        return amountOfTokens;
    }

    function burnTokens(address who, uint256 tokenAmount) internal returns(uint256) {
        //Compute the amount of counter to give them
        uint256 counterAmount = tokensToCounter(tokenAmount);
        //Burn the tokens
        burn(who, tokenAmount);
        //Send them their eth/counter
        if(counter == 0x0){
            who.transfer(counterAmount);
        }else{
            ERC20(counter).transfer(who, counterAmount);
        }
        // fire event
        emit Transfer(who, 0x0, tokenAmount);
        emit Sell(who, tokenAmount, counterAmount);
        //Return the amount of counter being sent
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