pragma solidity ^0.4.24;

/*
*
* https://fundingsecured.me/founders/
*
*  ███████╗ ██████╗ ██╗   ██╗███╗   ██╗██████╗ ███████╗██████╗
*  ██╔════╝██╔═══██╗██║   ██║████╗  ██║██╔══██╗██╔════╝██╔══██╗
*  █████╗  ██║   ██║██║   ██║██╔██╗ ██║██║  ██║█████╗  ██████╔╝
*  ██╔══╝  ██║   ██║██║   ██║██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗
*  ██║     ╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝███████╗██║  ██║
*  ╚═╝      ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝
*
*   ██████╗ █████╗ ██████╗ ██████╗ ███████╗
*  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝
*  ██║     ███████║██████╔╝██║  ██║███████╗
*  ██║     ██╔══██║██╔══██╗██║  ██║╚════██║
*  ╚██████╗██║  ██║██║  ██║██████╔╝███████║
*   ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝
*
* https://fundingsecured.me/founders/
*
*/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender)
        public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract FoundersCards {
    /*=================================
    =        MODIFIERS        =
    =================================*/
    modifier onlyOwner(){
        require(msg.sender == dev);
        _;
    }

    /*==============================
    =            EVENTS            =
    ==============================*/
    event oncardPurchase(
        address customerAddress,
        uint256 incomingEthereum,
        uint256 card,
        uint256 newPrice
    );

    event onWithdraw(
        address customerAddress,
        uint256 ethereumWithdrawn
    );

    // ERC20
    event Transfer(
        address from,
        address to,
        uint256 card
    );


    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "FOUNDER CARDS";
    string public symbol = "FOUNDERS";

    uint8 constant public fsDivRate = 10;
    uint8 constant public ownerDivRate = 50;
    uint8 constant public distDivRate = 40;
    uint8 constant public referralRate = 5;
    uint8 constant public decimals = 18;
    uint public totalCardValue = 6 ether; // Make sure this is sum of starting card values
    uint public precisionFactor = 9;


   /*================================
    =            DATASETS            =
    ================================*/

    mapping(uint => address) internal cardOwner;
    mapping(uint => uint) public cardPrice;
    mapping(uint => uint) internal cardPreviousPrice;
    mapping(address => uint) internal ownerAccounts;
    mapping(uint => uint) internal totalCardDivs;

    uint cardPriceIncrement = 110;
    uint totalDivsProduced = 0;

    uint public totalCards;

    uint ACTIVATION_TIME = 1537916399;

    address dev;
    address cs;
    address cf;
    address fundsDividendAddr;

    // Raffle Winners
    address w1;
    address w2;
    address w3;

    ERC20Basic fundingSecured;

    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --
    */
    constructor(address _fundingSecured)
        public
    {
        fundingSecured = ERC20Basic(_fundingSecured);
        dev = msg.sender;
        fundsDividendAddr = 0xeb0ec7a28e4b6b175806e21d9d3afe45792c5c7b;

        cs = 0xeb0ec7a28e4b6b175806e21d9d3afe45792c5c7b;
        cf = 0xeb0ec7a28e4b6b175806e21d9d3afe45792c5c7b;

        w1 = 0xeb0ec7a28e4b6b175806e21d9d3afe45792c5c7b;
        w2 = 0xeb0ec7a28e4b6b175806e21d9d3afe45792c5c7b;
        w3 = 0xeb0ec7a28e4b6b175806e21d9d3afe45792c5c7b;

        totalCards = 12;

        cardOwner[0] = w1;
        cardPrice[0] = 1.2 ether;
        cardPreviousPrice[0] = cardPrice[0];

        cardOwner[1] = w2;
        cardPrice[1] = 1 ether;
        cardPreviousPrice[1] = cardPrice[1];

        cardOwner[2] = w3;
        cardPrice[2] = 0.8 ether;
        cardPreviousPrice[2] = cardPrice[2];

        cardOwner[3] = cf;
        cardPrice[3] = 0.7 ether;
        cardPreviousPrice[3] = cardPrice[3];

        cardOwner[4] = cf;
        cardPrice[4] = 0.6 ether;
        cardPreviousPrice[4] = cardPrice[4];

        cardOwner[5] = cf;
        cardPrice[5] = 0.5 ether;
        cardPreviousPrice[5] = cardPrice[5];

        cardOwner[6] = cs;
        cardPrice[6] = 0.4 ether;
        cardPreviousPrice[6] = cardPrice[6];

        cardOwner[7] = cs;
        cardPrice[7] = 0.3 ether;
        cardPreviousPrice[7] = cardPrice[7];

        cardOwner[8] = cs;
        cardPrice[8] = 0.25 ether;
        cardPreviousPrice[8] = cardPrice[8];

        cardOwner[9] = dev;
        cardPrice[9] = 0.13 ether;
        cardPreviousPrice[9] = cardPrice[9];

        cardOwner[10] = dev;
        cardPrice[10] = 0.07 ether;
        cardPreviousPrice[10] = cardPrice[10];

        cardOwner[11] = dev;
        cardPrice[11] = 0.05 ether;
        cardPreviousPrice[11] = cardPrice[11];
    }

    function addtotalCardValue(uint _new, uint _old)
    internal
    {
        uint newPrice = SafeMath.div(SafeMath.mul(_new,cardPriceIncrement),100);
        totalCardValue = SafeMath.add(totalCardValue, SafeMath.sub(newPrice,_old));
    }

    function buy(uint _card, address _referrer, uint _price)
        public
    {
        require(_card < totalCards);
        require(now >= ACTIVATION_TIME);
        require(_price >= cardPrice[_card]);
        require(msg.sender != cardOwner[_card]);
        
        //Actually get the money, honey!
        require(fundingSecured.transferFrom(msg.sender, this, _price));

        // Return excess ether if buyer overpays
        if (_price > cardPrice[_card]){
            uint _excess = SafeMath.sub(_price, cardPrice[_card]);
            ownerAccounts[msg.sender] += _excess;
        }

        addtotalCardValue(cardPrice[_card], cardPreviousPrice[_card]);

        uint _newPrice = SafeMath.div(SafeMath.mul(cardPrice[_card], cardPriceIncrement), 100);

         //Determine the total dividends
        uint _baseDividends = SafeMath.sub(cardPrice[_card], cardPreviousPrice[_card]);

        totalDivsProduced = SafeMath.add(totalDivsProduced, _baseDividends);

        uint _fsDividends = SafeMath.div(SafeMath.mul(_baseDividends, fsDivRate),100);

        uint _ownerDividends = SafeMath.div(SafeMath.mul(_baseDividends, ownerDivRate), 100);

        totalCardDivs[_card] = SafeMath.add(totalCardDivs[_card], _ownerDividends);

        _ownerDividends = SafeMath.add(_ownerDividends, cardPreviousPrice[_card]);

        uint _distDividends = SafeMath.div(SafeMath.mul(_baseDividends, distDivRate), 100);

        // If referrer is left blank,send to FUND address
        if (_referrer != msg.sender) {

            uint _referralDividends = SafeMath.div(SafeMath.mul(_baseDividends, referralRate), 100);

            _distDividends = SafeMath.sub(_distDividends, _referralDividends);

            if (_referrer == 0x0) {
                //fundsDividendAddr.transfer(_referralDividends);
                require(fundingSecured.transfer(fundsDividendAddr, _referralDividends));
            }

            else {
                ownerAccounts[_referrer] = SafeMath.add(ownerAccounts[_referrer], _referralDividends);
            }
        }

        //distribute dividends to accounts
        address _previousOwner = cardOwner[_card];
        address _newOwner = msg.sender;

        ownerAccounts[_previousOwner] = SafeMath.add(ownerAccounts[_previousOwner], _ownerDividends);

        //fundsDividendAddr.transfer(_fsDividends);
        fundingSecured.transfer(fundsDividendAddr, _fsDividends);
        distributeDivs(_distDividends);

        //Increment the card Price
        cardPreviousPrice[_card] = cardPrice[_card];
        cardPrice[_card] = _newPrice;
        cardOwner[_card] = _newOwner;

        emit oncardPurchase(msg.sender, cardPreviousPrice[_card], _card, _newPrice);
    }


    function distributeDivs(uint _distDividends) internal{

            for (uint _card=0; _card < totalCards; _card++){

                uint _divShare = SafeMath.div(SafeMath.div(SafeMath.mul(cardPreviousPrice[_card], 10 ** (precisionFactor + 1)), totalCardValue) + 5, 10);
                uint _cardDivs = SafeMath.div(SafeMath.mul(_distDividends, _divShare), 10 ** precisionFactor);

                ownerAccounts[cardOwner[_card]] += _cardDivs;

                totalCardDivs[_card] = SafeMath.add(totalCardDivs[_card], _cardDivs);
            }
        }


    function withdraw()
        public
    {
        address _customerAddress = msg.sender;
        require(ownerAccounts[_customerAddress] >= 0.001 ether);

        uint _dividends = ownerAccounts[_customerAddress];
        ownerAccounts[_customerAddress] = 0;
        
        //_customerAddress.transfer(_dividends);
        fundingSecured.transfer(_customerAddress, _dividends);

        emit onWithdraw(_customerAddress, _dividends);
    }



    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    function setName(string _name)
        onlyOwner()
        public
    {
        name = _name;
    }


    function setSymbol(string _symbol)
        onlyOwner()
        public
    {
        symbol = _symbol;
    }

    function setcardPrice(uint _card, uint _price)   //Allow the changing of a card price owner if the dev owns it
        onlyOwner()
        public
    {
        require(cardOwner[_card] == dev);
        cardPrice[_card] = _price;
    }

    function addNewcard(uint _price)
        onlyOwner()
        public
    {
        cardPrice[totalCards-1] = _price;
        cardOwner[totalCards-1] = dev;
        totalCardDivs[totalCards-1] = 0;
        totalCards = totalCards + 1;
    }


    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Ethereum stored in the contract
     * Example: totalEthereumBalance()
     */


    function getMyBalance()
        public
        view
        returns(uint)
    {
        return ownerAccounts[msg.sender];
    }

    function getOwnerBalance(address _cardOwner)
        public
        view
        returns(uint)
    {
        return ownerAccounts[_cardOwner];
    }

    function getcardPrice(uint _card)
        public
        view
        returns(uint)
    {
        require(_card < totalCards);
        return cardPrice[_card];
    }

    function getcardOwner(uint _card)
        public
        view
        returns(address)
    {
        require(_card < totalCards);
        return cardOwner[_card];
    }

    function gettotalCardDivs(uint _card)
        public
        view
        returns(uint)
    {
        require(_card < totalCards);
        return totalCardDivs[_card];
    }

    function getTotalDivsProduced()
        public
        view
        returns(uint)
    {
        return totalDivsProduced;
    }

    function getCardDivShare(uint _card)
        public
        view
        returns(uint)
    {
        require(_card < totalCards);
        return SafeMath.div(SafeMath.div(SafeMath.mul(cardPreviousPrice[_card], 10 ** (precisionFactor + 1)), totalCardValue) + 5, 10);
    }

    function getCardDivs(uint  _card, uint _amt)
        public
        view
        returns(uint)
    {
        uint _share = getCardDivShare(_card);
        return SafeMath.div(SafeMath.mul( _share, _amt), 10 ** precisionFactor);
    }

    function gettotalCardValue()
        public
        view
        returns(uint)
    {

        return totalCardValue;
    }

    function totalBalance()
        public
        view
        returns(uint)
    {
        return fundingSecured.balanceOf(this);
    }

    function gettotalCards()
        public
        view
        returns(uint)
    {
        return totalCards;
    }

}
