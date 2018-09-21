pragma solidity ^0.4.25;
import "./Owned.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./Percent.sol";

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

contract Genr8 is Owned {
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
        require(totalTokens() == 0 && counterBalance() == 0);
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
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    bytes32 public name = "Genr8";
    bytes32 public symbol = "GN8";
    uint256 public sellRevenuePercent = 10;
    uint256 public percision = 100;
    uint8 public decimals = 18;
    address public counter = 0x0;
    

   /*================================
    =            DATASETS            =
    ================================*/
    // amount of tokens for each address
    mapping(address => uint256) internal tokenBalanceLedger;
    // amount of eth withdrawn
    mapping(address => int256) internal payoutsTo;
    // amount of tokens allowed to someone else 
    mapping(address => mapping(address => uint)) allowed;
    // the actual amount of tokens
    uint256 internal tokenSupply = 0;
    // the amount of dividends per token
    uint256 internal profitPerShare;
    
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /**
    * -- APPLICATION ENTRY POINTS --  
    */
    constructor() 
    public {
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
    function buy()
        public
        payable
        ethCounter
        returns(uint256)
    {
        if(msg.value > 0){
            require(counter == 0x0);
        }
        return purchaseTokens(msg.sender, msg.value);
    }
    

    /**
     * Converts all incoming counter to tokens for the caller
     */
    function buyERC20(uint256 amount)
        public
        erc20Counter
        returns(uint256)
    {
        require(ERC20Interface(counter).transferFrom(msg.sender, this, amount));
        return purchaseTokens(msg.sender, amount);
    }


    /**
     * Fallback function to handle counter that was sent straight to the contract.
     * Causes tokens to be purchased.
     */
    function()
        payable
        public
        ethCounter
    {
        emit Revenue(msg.value, msg.sender, "ETH Deposit");
    }
    
    /**
     * Create revenue without purchasing tokens
     */
    function donate() 
        payable
        public
    {
        emit Revenue(msg.value, msg.sender, "ETH Donation");
    }
    
    /**
     * Liquifies tokens to counter.
     */
    function sell(uint256 amountOfTokens)
        onlyTokenHolders
        public
        returns(uint256)
    {
        return sellTokens(msg.sender, amountOfTokens);
    }

    /**
     * Transfer tokens from the caller to a new holder.
     * Transfering ownership of tokens requires settling outstanding dividends
     * and transfering them back. You can therefore send 0 tokens to this contract to
     * trigger your withdraw.
     */
    function transfer(address toAddress, uint256 amountOfTokens)
        onlyTokenHolders
        public
        returns(bool)
    {

       // Sell on transfer in instead of transfering to us
        if(toAddress == address(this)){
            // If we sent in tokens, destroy them and credit their account with ETH
            if(amountOfTokens > 0){
                sell(amountOfTokens);
            }
            // fire event
            emit Transfer(msg.sender, 0x0, amountOfTokens);

            return true;
        }
       
        return _transfer(toAddress, amountOfTokens);
    }

    //ERC20
    function _transfer(address toAddress, uint256 amountOfTokens)
        internal
        onlyTokenHolders
        returns(bool)
    {
        // make sure we have the requested tokens
        require(amountOfTokens <= tokenBalanceLedger[msg.sender]);
       
        // exchange tokens
        tokenBalanceLedger[msg.sender] = SafeMath.sub(tokenBalanceLedger[msg.sender], amountOfTokens);
        tokenBalanceLedger[toAddress] = SafeMath.add(tokenBalanceLedger[toAddress], amountOfTokens);
        
        // fire event
        emit Transfer(msg.sender, toAddress, amountOfTokens);

        return true;
       
    }
    
    // ERC20 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    /**
    * Transfer `tokens` from the `from` account to the `to` account
    * 
    * The calling account must already have sufficient tokens approve(...)-d
    * for spending from the `from` account and
    * - From account must have sufficient balance to transfer
    * - Spender must have sufficient allowance to transfer
    * - 0 value transfers are allowed
    * 
    * Implementation taken from ERC20 reference
    * 
    */
    function transferFrom(address from, address to, uint tokens) onlyTokenHolders public returns (bool success) {
        require(tokens > 0 && tokenBalanceLedger[from] <= tokens && tokens <= allowed[from][msg.sender]);
        tokenBalanceLedger[from] = tokenBalanceLedger[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        tokenBalanceLedger[to] = tokenBalanceLedger[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    /**
    * Returns the amount of tokens approved by the owner that can be
    * transferred to the spender's account
    * 
    * Implementation taken from ERC20 reference
    * 
    */
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
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
     * Method to view the current Counter stored in the contract
     * Example: totalDestinationBalance()
     */
    function counterBalance()
        public
        view
        returns(uint256)
    {
        if(counter == 0x0){
            return address(this).balance;
        } else {
            return ERC20Interface(counter).balanceOf(this);
        }
    }
    
    /**
     * Retrieve the name of the token.
     */
    function name() 
        public 
        view 
        returns(bytes32)
    {
        return name;
    }
     

    /**
     * Retrieve the symbol of the token.
     */
    function symbol() 
        public
        view
        returns(bytes32)
    {
        return symbol;
    }
    
    /**
     * Retrieve the decimals of the token.
     */
    function decimals() 
        public
        view
        returns(uint8)
    {
        return decimals;
    }
    
    /**
     * Retrieve the spread percent applied upon selling 
     */
    function sellRevenuePercent() public view returns (uint256, uint256){
        return (sellRevenuePercent, percision);
    }
     
    /**
     * Retrieve the total token supply.
     */
    function totalTokens()
        public
        view
        returns(uint256)
    {
        return tokenSupply;
    }
    
    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens()
        public
        view
        returns(uint256)
    {
        return balanceOf(msg.sender);
    }

    
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger[customerAddress];
    }
    
    
    /**
     * Convert X tokens to Y counter
     */
    function tokensToCounter(uint256 anAmount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(SafeMath.div(SafeMath.mul(totalTokens(), percision), counterBalance()), anAmount),percision);
    }
    
    /**
     * Convert X counter to Y tokens
     */
    function counterToTokens(uint256 anAmount) public view returns(uint256){
        if(totalTokens() == 0){
            return anAmount;
        }
        return SafeMath.mul(SafeMath.div(anAmount, SafeMath.div(SafeMath.mul(totalTokens(), percision), counterBalance())), percision);
    }
    
    /**
     * Calculate the cost of selling X tokens
     */
    function revenueCost(uint256 anAmount) public view returns(uint256){
        return sellRevenuePercent > 0 ? SafeMath.mul(anAmount, sellRevenuePercent) / percision : 0;
    }
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(address who, uint256 incomingCounter) internal returns(uint256) {
        // book keeping
        uint256 amountOfTokens = counterToTokens(incomingCounter);

        // prevent overflow
        assert(amountOfTokens > 0 && (SafeMath.add(amountOfTokens,tokenSupply) > tokenSupply));
               
        // add tokens to the pool
        tokenSupply = SafeMath.add(tokenSupply, amountOfTokens);
 
        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger[who] = SafeMath.add(tokenBalanceLedger[who], amountOfTokens);
        
        // fire events
        emit Buy(who, incomingCounter, amountOfTokens);
        emit Transfer(0x0, who, amountOfTokens);
        return amountOfTokens;
    }

    function sellTokens(address who, uint256 anAmount) internal returns(uint256) {
        require(anAmount > 0);
        require(anAmount <= tokenBalanceLedger[who]);
        uint256 counterAmount = tokensToCounter(anAmount);
        uint256 revenue = revenueCost(anAmount);
        uint256 taxedCounter = SafeMath.sub(counterAmount, revenue);
        
        // burn the sold tokens
        tokenSupply = SafeMath.sub(tokenSupply, anAmount);
        tokenBalanceLedger[who] = SafeMath.sub(tokenBalanceLedger[who], anAmount);
        
        //Send them their eth/counter
        if(counter == 0x0){
            who.transfer(taxedCounter);
        }else{
            ERC20Interface(counter).transfer(who, taxedCounter);
        }
        
        // fire event
        emit Sell(who, anAmount, taxedCounter);
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
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}