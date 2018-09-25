pragma solidity ^0.4.24;
import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./Hourglass.sol";
import "./IronHands.sol";


contract LeadHands is Ownable, ERC721Token {
    /**
     * Constants
     */
     
    /**
     * Signature for ERC-721 received return code.
     */
    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;
    
    bytes4 internal constant ERC721_NOT_RECEIVED = bytes4(keccak256("We do not support receiving ERC-721."));

    bytes4 internal constant InterfaceSignature_ERC165 = 0x01ffc9a7;
    /*
    bytes4(keccak256('supportsInterface(bytes4)'));
    */

    bytes4 internal constant InterfaceSignature_ERC721 = 0x80ac58cd;
    /*
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('getApproved(uint256)')) ^
    bytes4(keccak256('setApprovalForAll(address,bool)')) ^
    bytes4(keccak256('isApprovedForAll(address,address)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
    bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'));
    */

    bytes4 internal constant InterfaceSignature_ERC721Metadata = 0x5b5e139f;
    /*
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('tokenURI(uint256)'));
    */

    bytes4 internal constant InterfaceSignature_ERC721Optional =- 0x4f558e79;
    /*
    bytes4(keccak256('exists(uint256)'));
    */
    
    
    /**
     * Modifiers
     */
     
    /**
     * The tokens from the source cannot be transfered.
     */
    modifier notSource(address aContract) {
        require(aContract != address(source));
        _;
    }
    
    /**
     * Only if this person owns the token or is approved
     */
    modifier ownerOrApproved(address _operator, uint256 _tokenId) {
        require(isApprovedOrOwner(_operator, _tokenId));
        _;
    }
    
    /**
     * Only if this person owns the token
     */
    modifier isTokenOwner(address _operator, uint256 _tokenId){
        require(_operator != 0x0 && ownerOf(_tokenId) == _operator);
        _;
    }
    
    /**
     * Only if the contract has a positive balance
     */
    modifier hasBalance() {
        require(address(this).balance > 10);
        _;
    }
    
   
    /**
     * Events
     */
    event Deposit(uint256 amount, address depositer);
    event Purchase(uint256 amountSpent, uint256 tokensReceived);
    event Payout(uint256 amount, address creditor);
    event EarlyExit(uint256 paid, uint256 owed, address deserter);
    event Dividends(uint256 amount);
    event Donation(uint256 amount, address donator);

    /**
     * Structs
     */
    struct Participant {
        address etherAddress;
        uint256 payout;
        uint256 tokens;
    }

    //Total ETH revenue over the lifetime of the contract
    uint256 output;
    //Total ETH received from dividends
    uint256 dividends;
    //The percent to return to depositers. 100 for 0%, 200 to double, etc.
    uint256 public multiplier;
    //Where in the line we are with creditors
    uint256 public payoutOrder = 0;
    //How much is owed to people
    uint256 public backlog = 0;
    //Number of Participants
    uint256 public participantsOwed = 0;
    //The creditor line
    Participant[] public participants;
    //How much each person is owed
    mapping(address => uint256) public creditRemaining;
    //What we will be buying
    Hourglass source;
    //IronHands, the other revenue source
    IronHands ironHands;
    //My name for ERC-721 metadata
    string myName;
    //My symbol for ERC-721 metadata
    string mySymbol;
    //tokenURI prefix which will have the tokenId appended to it
    string myTokenURIPrefix;
    
     /**
     * Constructor
     */
    constructor(uint256 multiplierPercent, address sourceAddress, address ironHandsAddress, string name, string symbol, string tokenURIPrefix) public {
        multiplier = multiplierPercent;
        source = Hourglass(sourceAddress);
        ironHands = IronHands(ironHandsAddress);
        myName = name;
        mySymbol = symbol;
        myTokenURIPrefix = tokenURIPrefix;
    }
    
        /**
     * Deposit ETH to get in line to be credited back the multiplier as a percent,
     * Add that ETH to the pool, then pay out who we owe and buy more tokens.
     */ 
    function deposit() payable public {
        //You have to send more than 1000000 wei, and we don't allow investment over 3x the debt owed to keep the backlog down.
        require(msg.value > 3000000 && (output == 0 || msg.value <= ((output * 3) - backlog)));
        //Compute how much to pay them
        uint256 amountCredited = (msg.value * multiplier) / 100;
        //Compute how much we're going to invest in each opportunity
        uint256 investment = msg.value / 3;
        //Split the deposit up and buy some future revenue from the source
        uint256 tokens = buyFromHourglass(investment);
        //And some ironHands revenue because that causes events in the future
        buyFromIronHands(investment);
        //Get in line to be paid back.
        participants.push(Participant(msg.sender, amountCredited, tokens));
        //Increase the backlog by the amount owed
        backlog += amountCredited;
        //Increase the number of participants owed
        participantsOwed++;
        //Increase the amount owed to this address
        creditRemaining[msg.sender] += amountCredited;
        //Give them the token
        _mint(msg.sender, participants.length-1);
        //Emit a deposit event.
        emit Deposit(msg.value, msg.sender);
        //Do the internal payout loop
        internalPayout();
    }
    
    /**
     * Take 50% of the money and spend it on tokens, which will pay dividends later.
     * Take the other 50%, and use it to pay off depositors.
     */
    function payout() public {
        //Take everything in the pool
        uint256 existingBalance = address(this).balance;
        //It needs to be something worth splitting up
        require(existingBalance > 10);
        //Balance split up to buy p3d tokens and IronHands
        uint256 investment = existingBalance.div(3);
        //Invest it in more revenue from the source.
        buyFromHourglass(investment);
        //And more revenue from IronHands.
        buyFromIronHands(investment);
        //Pay people out
        internalPayout();
    }
    
    /**
     * Internal payout loop called by deposit() and payout()
     */
    function internalPayout() hasBalance internal {
        //Get the balance
        uint256 existingBalance = address(this).balance;
         //While we still have money to send
        while (existingBalance > 0) {
            //Either pay them what they are owed or however much we have, whichever is lower.
            uint256 payoutToSend = existingBalance < participants[payoutOrder].payout ? existingBalance : participants[payoutOrder].payout;
            //if we have something to pay them
            if(payoutToSend > 0){
                //record how much we have paid out
                output += payoutToSend;
                //subtract how much we've spent
                existingBalance -= payoutToSend;
                //subtract the amount paid from the amount owed
                backlog -= payoutToSend;
                //subtract the amount remaining they are owed
                creditRemaining[participants[payoutOrder].etherAddress] -= payoutToSend;
                //credit their account the amount they are being paid
                participants[payoutOrder].payout -= payoutToSend;
                if(participants[payoutOrder].payout == 0){
                    //Decrease number of participants owed
                    participantsOwed--;
                }
                //Try and pay them, making best effort. But if we fail? Run out of gas? That's not our problem any more.
                if(participants[payoutOrder].etherAddress.call.value(payoutToSend).gas(1000000)()){
                    //Record that they were paid
                    emit Payout(payoutToSend, participants[payoutOrder].etherAddress);
                }else{
                    //undo the accounting, they are being skipped because they are not payable.
                    output -= payoutToSend;
                    existingBalance += payoutToSend;
                    backlog += payoutToSend;
                    backlog -= participants[payoutOrder].payout; 
                    creditRemaining[participants[payoutOrder].etherAddress] -= participants[payoutOrder].payout;
                    participants[payoutOrder].payout = 0;
                }
            }
            //check for possible reentry
            existingBalance = address(this).balance;
            //If we still have balance left over
            if(existingBalance > 0){
                //Go to the next person in line
                payoutOrder += 1;
                //Decrease number of participants owed
                participantsOwed--;
            }
            //If we've run out of people to pay, stop
            if(payoutOrder >= participants.length){
                return;
            }
        }
    }
    
    
    
    /**
     * Withdraw and payout in one transactions
     */
    function withdrawAndPayout() public {
        //if we have dividends
        if(myDividends() > 0){
            //withdraw them
            withdraw();
        }
        //payout everyone we can
        payout();
    }

    /**
     * Sells the tokens your investment bought, giving you whatever it received in doing so, and canceling your future payout.
     * Calling this with a position you own in line with forefit that future payout as well as 50% of your initial deposit.
     * This is here in response to people not being able to "get their money out early". Now you can, but at a very high cost.
     */
    function exit(uint256 _tokenId) ownerOrApproved(msg.sender, _tokenId) public {
        //Withdraw dividends first
        if(myDividends() > 0){
            withdraw();       
        }
        //Lock divs so not used to pay seller
        uint256 lockedFunds = address(this).balance;
        //Get tokens for this postion
        uint256 tokensToSell = participants[_tokenId].tokens;
        //Get the amount the are owed on this postion
        uint256 owedAmount = participants[_tokenId].payout;
        //Set tokens for this position to 0
        participants[_tokenId].tokens = 0;
        //Set amount owed on this position to 0
        participants[_tokenId].payout = 0;
        //Sell particpant's tokens
        source.sell(tokensToSell);
        //get the money out
        withdraw();
        //remove divs from funds to be paid
        uint256 availableFunds = address(this).balance - lockedFunds;
        //Set Backlog Amount
        backlog -= owedAmount;
        //Decrease number of participants
        participantsOwed--;
        //Check if owed amount is less than or equal to the amount available
        if (owedAmount <= availableFunds){
            //If more availabe funds are available only send owed amount
            earlyExit(owedAmount, msg.sender,owedAmount);
        }else{
            //If owed amount is greater than available amount send all available
            earlyExit(availableFunds, msg.sender,owedAmount);
        }
    }

    /**
     * Exit sending and accounting
     */
    function earlyExit(uint256 _amount, address _addr,uint256 _owed) internal {
        //Try and pay them, making best effort. But if we fail? Run out of gas? That's not our problem any more.
        _addr.call.value(_amount).gas(1000000)();
        //Record that they were paid
        emit EarlyExit(_amount, _owed, _addr);
        
    }

    /**
     * Request dividends be paid out and added to the pool.
     */
    function withdraw() public {
        //get our balance
        uint256 balance = address(this).balance;
        //withdraw however much we are owed
        source.withdraw.gas(1000000)();
        //remove the amount we already had from the calculation
        uint256 dividendsPaid = address(this).balance - balance;
        //increase the dividends we've been paid
        dividends += dividendsPaid;
        //emit and event
        emit Dividends(dividendsPaid);
    }

    /**
     * ERC-721 Metadata support for name
     */
    function name() external view returns (string _name){
        return myName;
    }

    /**
     * ERC-721 Metadata support for name
     */
    function symbol() external view returns (string _symbol){
        return mySymbol;
    }

    /**
     * The owner can change the name.
     */
    function setName(string _name) external onlyOwner {
      myName = _name;
    }   

    /**
     * The owner can change the symbol
     */
    function setSymbol(string _symbol) external onlyOwner {
      mySymbol = _symbol;
    }

    /**
     * The owner can set the tokeURI
     */
    function setTokenURI(string tokenURI) external onlyOwner {
      myTokenURIPrefix = tokenURI;
    }

    /**
     * Helper function for appending the tokenId to the URI
     */
    function appendUintToString(string inStr, uint v) internal pure returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    /**
     * Helper function for appending the tokenId to the URI
     */
    function uintToString(uint256 v) internal pure returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }

    /**
     * ERC-721 Metadata support for getting the token URI
     * Returns a unique URI per token
     */
    function tokenURI(uint256 _tokenId) public view returns (string){
        return appendUintToString(myTokenURIPrefix, _tokenId);
    }
    
    /**
     * Fallback function allows anyone to send money for the cost of gas which
     * goes into the pool. Used by withdraw/dividend payouts so it has to be cheap.
     */
    function() payable public {
    }
    
    /**
     * Buy some tokens from the revenue source
     */
    function buyFromHourglass(uint256 _amount) internal returns(uint256) {
        return source.buy.value(_amount).gas(1000000)(msg.sender);
    }
    
    /**
     * Invest in IronHands
     */
    function buyFromIronHands(uint256 _amount) internal {
        ironHands.deposit.value(_amount).gas(3000000)();
    }
    
    /**
     * Amount an individual token is owed in the future
     */
    function balanceOfToken(uint256 _tokenId) public view returns (uint256) {
        return participants[_tokenId].payout;
    }
    
    /**
     * Number of participants in line ahead of this token
     */
    function participantsAheadOfToken(uint256 _tokenId) public view returns (uint256) {
        require(payoutOrder <= _tokenId);
        return _tokenId - payoutOrder;
    }
    
    /**
     * Number of tokens the contract owns.
     */
    function myTokens() public view returns(uint256){
        return source.myTokens();
    }
    
    /**
     * Number of dividends owed to the contract.
     */
    function myDividends() public view returns(uint256){
        return source.myDividends(true);
    }
    
    /**
     * Number of dividends received by the contract.
     */
    function totalDividends() public view returns(uint256){
        return dividends;
    }
    
    /**
     * Number of dividends owed to the contract.
     */
    function positionsTokens(uint256 _tokenId) public view returns(uint256){
        return participants[_tokenId].tokens;
    }
    

    /**
     * A charitible contribution will be added to the pool.
     */
    function donate() payable public {
        emit Donation(msg.value, msg.sender);
    }
    
    /**
     * Number of participants who are still owed.
     */
    function backlogLength() public view returns (uint256){
        return participantsOwed;
    }
    
    /**
     * Total amount still owed in credit to depositors.
     */
    function backlogAmount() public view returns (uint256){
        return backlog;
    } 
    
    /**
     * Total number of deposits in the lifetime of the contract.
     */
    function totalParticipants() public view returns (uint256){
        return participants.length;
    }
    
    /**
     * Total amount of ETH that the contract has delt with so far.
     */
    function totalSent() public view returns (uint256){
        return output;
    }
    
    /**
     * Amount still owed to an individual address
     */
    function amountOwed(address anAddress) public view returns (uint256) {
        return creditRemaining[anAddress];
    }
     
     /**
      * Amount owed to this person.
      */
    function amountIAmOwed() public view returns (uint256){
        return amountOwed(msg.sender);
    }
    
    /**
     * A trap door for when someone sends tokens other than the intended ones so the overseers can decide where to send them.
     */
    function transferAnyERC20Token(address _tokenAddress, address _tokenOwner, uint256 _tokens) public onlyOwner notSource(_tokenAddress) returns (bool success) {
        return ERC20(_tokenAddress).transfer(_tokenOwner, _tokens);
    }
    
}