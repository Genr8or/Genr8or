pragma solidity ^0.4.24;
import "./MintableBurnableERC20Token.sol";
import "./Ownable.sol";

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


contract Genr8Interface{
    function purchaseTokens()
        public
        payable
        returns(uint256);

    function purchaseTokensERC20(uint256 amount)
        public
        returns(uint256);

    function withdraw()
        public;
}

contract Genr8orInterface {
    function genr8(
        bytes32 name, // Name of the DivvyUp
        bytes32 symbol,  // ERC20 Symbol fo the DivvyUp
        address counter, // The counter currency to accept. Example: 0x0 for ETH, otherwise the ERC20 token address.
        uint8 decimals // Number of decimals the token has. Example: 18        
     )  public 
        returns(address);
}

contract Genr8ICOFactory {

    event Create(bytes32 name,
        bytes32 symbol,
        address counter,
        uint8 decimals,
        uint256 launchBlockHeight,
        uint256 launchBalanceTarget,
        uint256 launchBalanceCap,
        address creator
    );


    Genr8ICO[] public registry;

    function genr8(        
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
        Genr8ICO ico = new Genr8ICO(name, symbol, counter, decimals, launchBlockHeight, launchBalanceTarget, launchBalanceCap, this);
        ico.transferOwnership(msg.sender);
        registry.push(ico);
        
        emit Create(name, symbol, counter, decimals, launchBlockHeight, launchBalanceTarget, launchBalanceCap, msg.sender);        
        return ico;   
    }

}

contract Genr8ICO is Ownable, MintableBurnableERC20Token {
    using SafeMath for uint256;
   
    modifier hasNotLaunched(){
        require(!hasLaunched);
        _;
    }

    modifier hasAlreadyLaunched(){
        require(hasLaunched);
        _;
    }

    modifier isReadyToLaunch(){
        require((block.number > launchBlockHeight || launchBlockHeight == 0) && (address(this).balance >= launchBalanceTarget));
        _;
    }

    modifier balanceHolder(){
        require(deposits[msg.sender] > 0);
        _;
    }

    bytes32 internal myName;
    bytes32 internal mySymbol;
    bytes32 internal iconame = "Genr8ICO";
    bytes32 internal icosymbol = "GR8ICO";
    uint8 public decimals = 18;
    uint256 public launchBlockHeight = 0;
    uint256 public launchBalanceTarget = 0;
    uint256 public launchBalanceCap = 0;
    bool public hasLaunched = false;
    address counter;
    address public destination;
    Genr8orInterface public factory;
    

    mapping(address => uint256) public deposits;
    mapping(address => mapping(address => uint)) allowed;
    uint256 public totalDeposits;

    function concat(string _base, string _value) internal pure returns (string) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i++];
        }

        return string(_newValue);
    }

    function bytes32ToString(bytes32 x) internal pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    function Genr8ICO(bytes32 aName, bytes32 aSymbol, address aCounter, uint8 aDecimals, uint256 aLaunchBlockHeight, uint256 aLaunchBalanceTarget, uint256 aLaunchBalanceCap, address aFactory) public {
        myName = aName;
        mySymbol = aSymbol;
        decimals = aDecimals;
        launchBlockHeight = aLaunchBlockHeight;
        launchBalanceTarget = aLaunchBalanceTarget;
        launchBalanceCap = aLaunchBalanceCap;
        counter = aCounter;
        factory = Genr8orInterface(aFactory);
    }


    function() public payable {
        if(msg.value == 0 && hasLaunched){
            withdraw(balanceOf(msg.sender));
            return;
        }
        require(!hasLaunched);
        require(launchBalanceCap == 0 || totalDeposits.add(msg.value) <= launchBalanceCap);
        require(counter == 0x0);
        mint(msg.sender, msg.value);
    }

    function depositERC20(uint256 amount) public {
        if(amount == 0 && hasLaunched){
            withdraw(balanceOf(msg.sender));
            return;
        }
        require(!hasLaunched);
        require(launchBalanceCap == 0 || totalDeposits.add(amount) <= launchBalanceCap);
        require(counter != 0x0);
        require(ERC20(counter).transferFrom(msg.sender, this, amount));
        mint(msg.sender, amount);
    }


    function name() public view returns(bytes32){
        return iconame;
    }

    function symbol() public view returns(bytes32){
        return icosymbol;
    }

    function decimals() public view returns(uint8){
        if(!hasLaunched){
            return 18;
        }else{
            return decimals;
        }
    }

    function launch() public hasNotLaunched isReadyToLaunch returns (address) {
        hasLaunched = true;
        destination = factory.genr8(myName, mySymbol, counter, decimals);
        Ownable(destination).transferOwnership(owner);
        if(totalDeposits > 0){
            if(counter == 0x0){
                Genr8Interface(destination).purchaseTokens.value(totalDeposits)();
            } else {
                Genr8Interface(destination).purchaseTokensERC20(totalDeposits);
            }
        }
    }

    function myBalance() public view returns (uint256) {
        return balanceOf(msg.sender);
    }

    function balanceOf(address anAddress) public view returns (uint256){
        if(!hasLaunched){
            return super.balanceOf(anAddress);
        }else{
            return ERC20(destination).balanceOf(this).div(totalDeposits.div(super.balanceOf(anAddress)));//TODO fix this math it's broken badly
        }
    }

    
    function withdraw(uint256 amount) public returns (bool) {
        require(balanceOf(msg.sender) <= amount);
        if(hasLaunched){
            uint256 ethEqulivent = ERC20(destination).balanceOf(this).div(amount);
            uint256 withdrawAmount = totalDeposits.div(ethEqulivent);
            burn(msg.sender, amount);
            require(ERC20(destination).transfer(msg.sender, ERC20(destination).balanceOf(this).div(amount)));//TODO fix this math too, it's likely broken.
        }else{
            totalDeposits -= amount;
            deposits[msg.sender] -= amount;
            if(deposits[msg.sender] == 0){
                delete deposits[msg.sender];
            }
            if(counter == 0x0){
                msg.sender.transfer(amount);
            } else{
                require(ERC20(counter).transfer(msg.sender, amount));
            }
        }
        return true;
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