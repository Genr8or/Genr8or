pragma solidity ^0.4.24;

import "./BackedERC20Token.sol";

contract Bankroll is BackedERC20Token {

    modifier ethCounter(){
        require(counter == 0x0);
        _;
    }

    modifier whitelisted(){
        require(isWhitelisted(msg.sender));
        _;
    }

    struct Quota{
        uint256 inQuota;
        uint256 outQuota;
        uint256 maxQuota;
    }

    event QuotaRecord(
        uint256 inQuota,
        uint256 outQuota,
        uint256 maxQuota,
        address source
    );

    event QuotaIssued(
        uint256 inQuota,
        uint256 outQuota,
        uint256 maxQuota,
        address source
    );

    event Whitelisted(
        address source
    );

    event Unwhitelisted(
        address source
    );
    

    address[] public whitelist;
    mapping(address => Quota) public quotas;
    mapping(address => uint256) public delinquent;
    uint256 public lastQuota = 0;
    uint256 constant public BLOCKS_BETWEEN_QUOTAS = 5760;
    constructor(string name, string symbol, uint8 decimals, address _counter, uint256 _precision) public BackedERC20Token(name, symbol, decimals, _counter, _precision){

    }

    function isWhitelisted(address anAddress) public view returns (bool){
        for(uint256 x = 0; x < whitelist.length; x++){
            if(anAddress == whitelist[x]){
                return true;
            }
        }
        return false;
    }

    function whitelist(address anAddress) internal {
        whitelist.push(anAddress);
        emit Whitelisted(anAddress);
    }

    function indexOf(address[] array, address anAddress) internal pure returns(uint256){
        for(uint256 x = 0; x < array.length; x++){
            if(anAddress == array[x]){
                return x;
            }
            raise("Cannot find item in the array.");
        }
    }

    function unwhitelist(address anAddress) internal {
        whitelist = remove(whitelist, indexOf(whitelist, anAddress));
        emit Unwhitelisted(anAddress);
    }

    function remove(address[] array, uint256 index)  returns(address[]) {
        if (index >= array.length) return;
        for (uint256 i = index; i<array.length-1; i++){
            array[i] = array[i+1];
        }
        delete array[array.length-1];
        array.length--;
        return array;
    }

    function deposit() public payable ethCounter whitelisted {
        quotas[msg.sender].inQuota += msg.value;
    }

    function depositERC20(uint256 anAmount) public erc20Counter whitelisted {
        require(ERC20(counter).transferFrom(msg.sender, this, anAmount));
        quotas[msg.sender].inQuota += anAmount;
    }

    function withdraw(uint256 amount) public whitelisted {
        if(quotas[msg.sender].inQuota > quotas[msg.sender].outQuota){
            require(amount <= quotas[msg.sender].maxQuota + (quotas[msg.sender].inQuota - quotas[msg.sender].outQuota)));
        }else{
            require((quotas[msg.sender].outQuota - quotas[msg.sender].inQuota) + amount <= quotas[msg.sender].maxQuota + (quotas[msg.sender].inQuota - quotas[msg.sender].outQuota));
        }
        quotas[msg.sender].outQuota += amount;
        if(counter == 0x0){
            msg.sender.transfer(amount);
        }else{
            ERC20(counter).transfer(msg.sender, amount);
        }
    }

    function checkQuotas() public {
        if(lastQuota + BLOCKS_BETWEEN_QUOTAS <= block.number){
            assignQuotas();
        }
    }

    function assignQuotas() internal {
        for(uint256 x = 0; x < whitelist.length; x++){
            emit QuotaRecord(quotas[whitelist[x]].inQuota, quotas[whitelist[x]].outQuota, quotas[whitelist[x]].maxQuota, whitelist[x]);
            if(quotas[whitelist[x]].inQuota >= quotas[whitelist[x]].outQuota){
                deliquent[whitelist[x]] = 0;
            }else{
                deliquent[whitelist[x]] += 1;
                if(deliquent[whitelist[x]] >= 7){
                    unwhitelist(whitelist[x]);
                    x--;
                    
                }
            }
        }
        uint256 newQuota = (counterBalance() / 2) / whitelist.length;
        for(uint256 x = 0; x < whitelist.length; x++){
            quotas[whitelist[x]] = Quota(0,0,newQuota);
        }
        lastQuota = block.number;
    }

    function checkQuota(address anAddress) public view returns (uint256, uint256, uint256){
        return (quotas[x].inQuota, quotas[x].outQuota, quotas[x].maxQuota);
    }

    funct6ion myQuota() public view returns (uint256, uint256, uint256){
        return checkQuota(msg.sender);
    }

    
}