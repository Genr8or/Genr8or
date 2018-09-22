pragma solidity ^0.4.24;
import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./Percent.sol";
import "./MintableBurnableERC20Token.sol";

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

contract Genr8 is Ownable, MintableBurnableERC20Token {
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
        require(totalSupply == 0 && counterBalance() == 0);
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
    =            CONFIGURABLES            =
    =====================================*/
    bytes32 public name = "Genr8";
    bytes32 public symbol = "GN8";
    uint256 public sellRevenuePercent = 10;
    uint256 public percision = 100;
    uint8 public decimals = 18;
    address public counter = 0x0;
        
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /**
    * -- APPLICATION ENTRY POINTS --  
    */
    constructor() public {
    }
    
    /**
     * Allows the owner to change the name of the contract
     */
    function setName(bytes32 newName) onlyOwner public {
        name = newName;
        
    }
    
    /**
     * Allows the owner to change the symbol of the contract
     */
    function setSymbol(bytes32 newSymbol) onlyOwner public {
        symbol = newSymbol;
    }
    
    /**
     * Allows the owner to change the decimals of the counter in case
     * they want to support an ERC-20 token with less decimals than 18
     * Only works prior to money being in the contract
     */
    function setDecimals(uint8 _decimals) onlyPreLaunch onlyOwner public {
        decimals = _decimals;
    }

    /**
     * Allows the owner to change the revenue cost on selling as a percent
     * Only works prior to money being in the contract
     */
    function setSellRevenuePercent(uint256 _sellRevenuePercent, uint256 _percision) onlyPreLaunch onlyOwner public {
        sellRevenuePercent = _sellRevenuePercent;
        percision = _percision;
    }
    
    /**
     * Allows the owner to change the decimals of the counter in case
     * they want to support an ERC-20 token with less decimals than 18
     * Only works prior to there being money in the contract
     */
    function setCounter(address _counter) onlyPreLaunch onlyOwner public {
        counter = _counter;
    }
    
    /**
     * Converts all incoming counter to tokens for the caller
     */
    function buy() public payable ethCounter returns(uint256) {
        if(msg.value > 0){
            require(counter == 0x0);
        }
        return purchaseTokens(msg.sender, msg.value);
    }
    

    /**
     * Converts all incoming counter to tokens for the caller
     */
    function buyERC20(uint256 amount) public erc20Counter returns(uint256) {
        require(ERC20(counter).transferFrom(msg.sender, this, amount));
        return purchaseTokens(msg.sender, amount);
    }


    /**
     * Fallback function to handle counter that was sent straight to the contract.
     * Causes tokens to be purchased.
     */
    function() payable public ethCounter {
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
            // If we sent in tokens, destroy them and credit their account with ETH
            if(amountOfTokens > 0){
                sellTokens(msg.sender, amountOfTokens);
            }   
            return true;
        }
        return super.transfer(toAddress, amountOfTokens);
    }

    /**
    * Token owner can approve for `spender` to transferFrom(...) `tokens`
    * from the token owner's account. The `spender` contract function
    * `receiveApproval(...)` is then executed
    * 
    */
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
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
     * Retrieve the name of the token.
     */
    function name() public view returns(bytes32) {
        return name;
    }
     
    /**
     * Retrieve the symbol of the token.
     */
    function symbol() public view returns(bytes32) {
        return symbol;
    }
    
    /**
     * Retrieve the decimals of the token.
     */
    function decimals() public view returns(uint8) {
        return decimals;
    }
    
    /**
     * Retrieve the spread percent applied upon selling 
     */
    function sellRevenuePercent() public view returns (uint256, uint256) {
        return (sellRevenuePercent, percision);
    }
     
    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens() public view returns(uint256) {
        return balanceOf(msg.sender);
    }
    
    /**
     * Convert X tokens to Y counter
     */
    function tokensToCounter(uint256 anAmount) public view returns(uint256) {
        if(totalSupply == 0){
            return anAmount;
        }
        return SafeMath.div(SafeMath.mul(SafeMath.div(SafeMath.mul(totalSupply, percision), counterBalance()), anAmount),percision);
    }
    
    /**
     * Convert X counter to Y tokens
     */
    function counterToTokens(uint256 anAmount) public view returns(uint256) {
        if(totalSupply == 0){
            return anAmount;
        }
        return SafeMath.mul(SafeMath.div(anAmount, SafeMath.div(SafeMath.mul(totalSupply, percision), counterBalance())), percision);
    }
    
    /**
     * Calculate the cost of selling X tokens
     */
    function revenueCost(uint256 anAmount) public view returns(uint256) {
        return sellRevenuePercent > 0 ? SafeMath.mul(anAmount, sellRevenuePercent) / percision : 0;
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
        uint256 revenue = revenueCost(counterAmount);
        uint256 taxedCounter = SafeMath.sub(counterAmount, revenue);
        burn(who, tokenAmount);
        //Send them their eth/counter
        if(counter == 0x0){
            who.transfer(taxedCounter);
        }else{
            ERC20(counter).transfer(who, taxedCounter);
        }
        
        // fire event
        emit Sell(who, tokenAmount, taxedCounter);
        emit Transfer(who, 0x0, tokenAmount);
        if(revenue > 0){
            emit Revenue(revenue, who, "Sale of tokens");
        }
        return taxedCounter;
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