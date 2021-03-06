pragma solidity ^0.4.24;
import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./IronHandsInterface.sol";
import "./HourglassInterface.sol";

contract LeadHands is Ownable, ERC721Token {
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
     * Only if the contract has a positive balance
     */
    modifier hasBalance() {
        require(address(this).balance > 10);
        _;
    }

    /*
     * Only if we can mint that many bonds, and they sent enough to buy a single bond
     */
    modifier canMint(uint256 amount){
        require(amount > 3000000 && (revenue == 0 || amount <= totalPurchasableBonds()));
        if(bondValue > 0){
            require(amount >= bondValue);
        }
        _;
    }
    
    /**
     * Events
     */
    event BondCreated(uint256 amount, address depositer, uint256 bondId);
    event Payout(uint256 amount, address creditor, uint256 bondId);
    event BondPaidOut(uint256 bondId);
    event BondDestroyed(uint256 paid, uint256 owed, address deserter, uint256 bondId);
    event Revenue(uint256 amount, address revenueSource);
    event Donation(uint256 amount, address donator);

    /**
     * Structs
     */
    struct Participant {
        address etherAddress;
        uint256 payout;
        uint256 tokens;
    }

    /**
     * Storage variables
     */
    //Total ETH revenue over the lifetime of the contract
    uint256 revenue;
    //Total ETH received from dividends
    uint256 dividends;
    //Total ETH donated to the contract
    uint256 donations;
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
    HourglassInterface source;
    //IronHands, the other revenue source
    IronHandsInterface ironHands;
    //tokenURI prefix which will have the tokenId appended to it
    string myTokenURIPrefix;
    //Bond value per bond, or 0 for user sized bonds.
    uint256 bondValue;
    //Amount of inflation to allow, or 0 for unlimited inflation
    uint256 inflationMultiplier;
    
     /**
     * Constructor
     */
    constructor(uint256 myBondValue, uint256 myInflationMultipler, uint256 multiplierPercent, address sourceAddress, address ironHandsAddress, string name, string symbol, string tokenURIPrefix) public ERC721Token(name, symbol) {
        multiplier = multiplierPercent;
        source = HourglassInterface(sourceAddress);
        ironHands = IronHandsInterface(ironHandsAddress);
        myTokenURIPrefix = tokenURIPrefix;
        bondValue = myBondValue;
        inflationMultiplier = myInflationMultipler;
    }
    
    /**
     * Deposit ETH to get in line to be credited back the multiplier as a percent,
     * Add that ETH to the pool, then pay out who we owe and buy more tokens.
     */ 
    function purchaseBond() payable canMint(msg.value) public returns (uint256[]){
        //A single bond is fixed at bond value, or 0 for user defined value on buy
        uint256 amountPerBond = bondValue == 0 ? msg.value : bondValue;
        //The amount they have deposited
        uint256 remainder = msg.value;
        //The issued bonds
        uint256[] memory issuedBonds = new uint256[](0);
        //counter for storing the bonds in the issuedBonds array
        uint256 issuedBondsIndex = 0;
        //while we still have money to spend
        while(remainder >= amountPerBond){
            remainder -= bondValue;
            //Compute how much to pay them
            uint256 amountCredited = bondValue.mul(multiplier).div(100);
            //Compute how much we're going to invest in each opportunity
            uint256 tokens = invest(bondValue);
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
            //Add it to the list of bonds they bought
            issuedBonds[issuedBondsIndex] = participants.length-1;
            //increment the issuedBondsIndex counter
            issuedBondsIndex++;
            //Emit a deposit event.
            emit BondCreated(bondValue, msg.sender, participants.length-1);
        }
        //If they sent in more than the bond value
        if(remainder > 0){
            //Send them back the portion they are owed.
            msg.sender.transfer(remainder);
        }
        //Do the internal payout loop
        internalPayout();
        //Tell them what bonds were issued to them
        return issuedBonds;
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
        invest(existingBalance);
        //Pay people out
        internalPayout();
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
        require(participants[_tokenId].tokens > 0 && participants[_tokenId].payout > 0);
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
        uint256 payment;
        //Check if owed amount is less than or equal to the amount available
        if (owedAmount <= availableFunds){
            //If more availabe funds are available only send owed amount
            payment = owedAmount;
        }else{
            //If owed amount is greater than available amount send all available
            payment = availableFunds;
        }
        //Try and pay them, making best effort. But if we fail? Run out of gas? That's not our problem any more.
        if(msg.sender.call.value(payment).gas(1000000)()){
            //Record that they were paid
            emit BondDestroyed(payment, owedAmount, msg.sender, _tokenId);
        }
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
        uint256 revenuePaid = address(this).balance - balance;
        //increase the dividends we've been paid
        revenue += revenuePaid;
        //emit and event
        emit Revenue(revenuePaid, source);
    }

    /**
     * The owner can set the tokeURI
     */
    function setTokenURI(string tokenURI) external onlyOwner {
      myTokenURIPrefix = tokenURI;
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
    function balanceOfBond(uint256 _tokenId) public view returns (uint256) {
        return participants[_tokenId].payout;
    }

    /**
     * Payout address of a given bond
     */
    function payoutAddressOfBond(uint256 _tokenId) public view returns (address) {
        return participants[_tokenId].etherAddress;
    }
    
    /**
     * Number of participants in line ahead of this token
     */
    function participantsAheadOfBond(uint256 _tokenId) public view returns (uint256) {
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
     * Number of donations received by the contract.
     */
    function totalDonations() public view returns(uint256){
        return donations;
    }

    /**
     * Number of dividends owed to the contract.
     */
    function tokensForBond(uint256 _tokenId) public view returns(uint256){
        return participants[_tokenId].tokens;
    }
    
    /**
     * A charitible contribution will be added to the pool.
     */
    function donate() payable public {
        require(msg.value > 0);
        donations += msg.value;
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
     * Total number of bonds issued in the lifetime of the contract.
     */
    function totalBondsIssued() public view returns (uint256){
        return participants.length;
    }

    /**
     * Total purchasable tokens.
     */
    function totalPurchasableBonds() public view returns (uint256){
        //If we don't have a limit on inflation
        if(inflationMultiplier == 0){
            //It's never over 9000
            return 9000 ether;
        }
        //Take the revenue, multipliy it by the inflationMultiplier, and subtract the backlog
        return revenue.mul(inflationMultiplier).sub(backlog);
    }
    
    /**
     * Total amount of ETH that the contract has issued back to it's investors.
     */
    function totalRevenue() public view returns (uint256){
        return revenue;
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

    function viewBond(uint256 _bondId) public view returns (address, uint256, uint256){
        return (participants[_bondId].etherAddress, participants[_bondId].payout, participants[_bondId].tokens);
    }
    
    /**
     * A trap door for when someone sends tokens other than the intended ones so the overseers can decide where to send them.
     */
    function transferAnyERC20Token(address _tokenAddress, address _tokenOwner, uint256 _tokens) public onlyOwner notSource(_tokenAddress) returns (bool success) {
        return ERC20(_tokenAddress).transfer(_tokenOwner, _tokens);
    }

    /**
     * Internal functions
     */

    /**
     * Split revenue either two or three ways, returning the number of tokens generated in doing so
     */
    function invest(uint256 amount) private returns (uint256){
        //Compute how much we're going to invest in each opportunity
        uint256 investment;
        //If we have an existing IronHands to piggyback on
        if(ironHands != address(0)){
            //Do a three way split
            investment = amount.div(3);
            //Buy some ironHands revenue because that causes events in the future
            buyFromIronHands(investment);
        }else{
            //Do a two way split
            investment = amount.div(2);
        }
        //Split the deposit up and buy some future revenue from the source
        return buyFromHourglass(investment);
    }

    /**
     * Internal payout loop called by deposit() and payout()
     */
    function internalPayout() hasBalance private {
        //Get the balance
        uint256 existingBalance = address(this).balance;
         //While we still have money to send
        while (existingBalance > 0) {
            //Either pay them what they are owed or however much we have, whichever is lower.
            uint256 payoutToSend = existingBalance < participants[payoutOrder].payout ? existingBalance : participants[payoutOrder].payout;
            //if we have something to pay them
            if(payoutToSend > 0){
                //record how much we have paid out
                revenue += payoutToSend;
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
                    emit Payout(payoutToSend, participants[payoutOrder].etherAddress, payoutOrder);
                }else{
                    //undo the accounting, they are being skipped because they are not payable.
                    revenue -= payoutToSend;
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
            if(participants[payoutOrder].payout == 0){
                //Log event
                emit BondPaidOut(payoutOrder);
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
     * Helper function for appending the tokenId to the URI
     */
    function appendUintToString(string inStr, uint v) private pure returns (string str) {
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
    function uintToString(uint256 v) private pure returns (string str) {
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

    
}