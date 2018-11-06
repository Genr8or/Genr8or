pragma solidity ^0.4.24;

import "./BackedERC20Token.sol";

contract IndexFund is BackedERC20Token {

    modifier ethCounter(){
        require(counter == 0x0);
        _;
    }

    modifier erc20Counter(){
        require(counter != 0x0);
        _;
    }

    modifier whitelisted(){
        require(isWhitelisted(msg.sender));
        _;
    }

    enum ProposalState{
        PROPOSED,
        APPROVED,
        ACTIVATED,
        VETOED
    }

    enum ProposalType{
        WHITELIST,
        BLACKLIST,
        BLOCKS_BETWEEN_QUOTAS,
        COOL_OFF_PERIOD,
        PROPOSAL_COST
    }

    struct Quota{
        uint256 inQuota;
        uint256 outQuota;
        uint256 maxQuota;
    }

    struct Proposal {
        uint256 votes;
        uint256 vetos;
        address source;
        uint256 value;
        ProposalState proposalState;
        ProposalType proposalType;
        uint256 blockApproved;
    }

    event ProposalCreated (
        address creator,
        address source,
        uint256 value,
        ProposalState proposalState,
        ProposalType proposalType,
        uint256 blockApproved
    );

    event ProposalVoteCast(
        uint256 proposalId,
        address voter,
        uint256 voteAmount,
        uint256 totalVotes
    );

    event ProposalVetoCast(
        uint256 proposalId,
        address vetoer,
        uint256 vetoerAmount,
        uint256 totalVetos
    );

    event ProposalApproved(
        uint256 proposalId
    );

    event ProposalVetoed (
        uint256 proposalId
    );

    event ProposalActivated (
        uint256 proposalId
    );

    event Investment(
        address source,
        uint256 counter,
        uint256 tokens
    );

    event Divestment(
        address source,
        uint256 counter,
        uint256 tokens
    );

    event Deposit(
        address source,
        uint256 amount
    );

    event Withdraw(
        address source,
        uint256 amount
    );

    event QuotaUsage(
        address source,
        uint256 inQuota,
        uint256 outQuota,
        uint256 maxQuota
    );

    event QuotaIssued(
        address source,
        uint256 maxQuota
    );

    event Delinquent(
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
    uint256 public blocksBetweenQuotas = 5760;
    uint256 public coolOffPeriod = 5760 * 14;
    uint256 public proposalCost = 0.5 ether;
    Proposal[] public proposals;
    mapping(address => uint256) staked;
    mapping(address => uint256) stakedOn;   
    mapping(address => uint256) vetoed;
    mapping(address => uint256) vetoedOn;     
    
    constructor(string name, string symbol, uint8 decimals, address _counter, uint256 _precision) public BackedERC20Token(name, symbol, decimals, _counter, _precision){

    }

    function createProposal(ProposalType aType, address source, uint256 value) public payable ethCounter returns (uint256){
        require(msg.value >= proposalCost);
        emit ProposalCreated(msg.sender, source, aType, value);
        return proposals.push(Proposal(0, 0, source, value, ProposalState.PROPOSED, aType, 0)) - 1;
    }

    function unvote() public {
        if(staked[msg.sender] == 0){
            return;
        }
        if(proposals[stakedOn[msg.sender]].proposalState != ProposalState.PROPOSED){
            staked[msg.sender] = 0;
            return;
        }
        proposals[stakedOn[msg.sender]].votes -= staked[msg.sender];
        staked[msg.sender] = 0;
    }

    function unveto() public {
        if(vetoed[msg.sender] == 0){
            return;
        }
        if(proposals[vetoedOn[msg.sender]].proposalState != ProposalState.APPROVED){
            vetoed[msg.sender] = 0;
            return;
        }
        proposals[vetoedOn[msg.sender]].votes -= staked[msg.sender];
        vetoed[msg.sender] = 0;
    }

    function vote(uint256 proposal, uint256 anAmount) public {
        require(proposal < proposals.length);
        require(anAmount <= balanceOf(msg.sender));
        require(proposals[proposal].proposalState == ProposalState.PROPOSED);
        unvote();
        proposals[proposal].votes += anAmount;
        staked[msg.sender] = anAmount;
        stakedOn[msg.sender] = proposal;
        emit ProposalVoteCast(proposal, msg.sender, anAmount, proposals[proposal].votes);
        updateProposal(proposal);
    }

    function updateProposal(uint256 proposal) public {
        require(proposal < proposals.length);
        require(proposals[proposal].proposalState == ProposalState.PROPOSED);
        if(proposals[proposal].votes > totalSupply() / 2){
            if(proposals[proposal].proposalType == ProposalType.BLACKLIST){
                unwhitelist(indexOf(whitelist, proposals[proposal].source));
                proposals[proposal].proposalState = ProposalState.ACTIVATED;
                emit ProposalActivated(proposal);
                return;
            }
            emit ProposalApproved(proposal);
            proposals[proposal].proposalState = ProposalState.APPROVED;
            proposals[proposal].blockApproved = block.number;
        }
    }

    function veto(uint256 anAmount, uint256 proposal) public {
        require(proposal < proposals.length);
        require(anAmount <= balanceOf(msg.sender));
        require(proposals[proposal].proposalState == ProposalState.APPROVED);
        unveto();
        proposals[proposal].vetos += anAmount;
        vetoed[msg.sender] = anAmount;
        vetoedOn[msg.sender] = proposal;
        emit ProposalVetoCast(proposal, msg.sender, anAmount, proposals[proposal].votes);
        if(proposals[proposal].vetos > totalSupply() / 2){
            proposals[proposal].proposalState = ProposalState.VETOED;
            emit ProposalVetoed(proposal);
        }
    }

    function activateProposal(uint256 proposal) public {
        require(proposal < proposals.length);
        require(proposals[proposal].proposalState == ProposalState.APPROVED);
        require(proposals[proposal].blockApproved + coolOffPeriod <= block.number);
        if(proposals[proposal].proposalType == ProposalType.WHITELIST){
            whitelist(proposals[proposal].source);
        }else if(proposals[proposal].proposalType == ProposalType.BLOCKS_BETWEEN_QUOTAS){
            blocksBetweenQuotas = proposals[proposal].value;
        }else if(proposals[proposal].proposalType == ProposalType.COOL_OFF_PERIOD){
            coolOffPeriod = proposals[proposal].value;
        }else if(proposals[proposal].proposalType == ProposalType.PROPOSAL_COST){
            proposalCost = proposals[proposal].value;
        }
        proposals[proposal].proposalState = ProposalState.ACTIVATED;
        emit ProposalActivated(proposal);
    }

    function transfer(address destination, uint256 amount) public returns (bool){
        unvote();
        unveto();
        return super.transfer(destination, amount);
    }

    function transferFrom(address source, address destination, uint256 amount) public returns (bool){
        unvote();
        unveto();
        return super.transferFrom(source, destination, amount);
    }

    function invest() public payable ethCounter returns (uint256){
        require(msg.value > 1000000);
        uint256 tokens = counterToTokens(msg.value);
        mint(msg.sender, tokens);
        emit Investment(msg.sender, msg.value, tokens);
        return tokens;
    }

    function investERC20(uint256 anAmount) public payable erc20Counter returns (uint256){
        require(ERC20(counter).transferFrom(msg.sender, this, anAmount));
        uint256 tokens = counterToTokens(anAmount);
        mint(msg.sender, tokens);
        emit Investment(msg.sender, anAmount, tokens);
        return tokens;
    }

    function divest(uint256 anAmount) public returns (uint256){
        require(anAmount <= balanceOf(msg.sender));
        unvote();
        unveto();
        uint256 toSend = tokensToCounter(anAmount);
        burn(msg.sender, anAmount);
        send(msg.sender, toSend);
        emit Divestment(msg.sender, anAmount, toSend);
        return toSend;
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
            revert("Cannot find item in the array.");
        }
    }

    function unwhitelist(uint256 index) internal {
        address toBeRemoved = whitelist[index];
        removeFromWhitelist(index);
        emit Unwhitelisted(toBeRemoved);
    }

    function deposit() public payable ethCounter whitelisted {
        checkQuotas();
        quotas[msg.sender].inQuota += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function depositERC20(uint256 anAmount) public erc20Counter whitelisted {
        checkQuotas();
        require(ERC20(counter).transferFrom(msg.sender, this, anAmount));
        quotas[msg.sender].inQuota += anAmount;
        emit Deposit(msg.sender, anAmount);
    }

    function withdraw(uint256 amount) public whitelisted {
        checkQuotas();
        if(quotas[msg.sender].inQuota > quotas[msg.sender].outQuota){
            require(amount <= quotas[msg.sender].maxQuota + (quotas[msg.sender].inQuota - quotas[msg.sender].outQuota));
        }else{
            require((quotas[msg.sender].outQuota - quotas[msg.sender].inQuota) + amount <= quotas[msg.sender].maxQuota + (quotas[msg.sender].inQuota - quotas[msg.sender].outQuota));
        }
        quotas[msg.sender].outQuota += amount;
        send(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function checkQuotas() public {
        if(lastQuota + blocksBetweenQuotas <= block.number){
            assignQuotas();
        }
    }

    function assignQuotas() internal {
        for(uint256 x = 0; x < whitelist.length; x++){
            emit QuotaUsage(whitelist[x], quotas[whitelist[x]].inQuota, quotas[whitelist[x]].outQuota, quotas[whitelist[x]].maxQuota);
            if(quotas[whitelist[x]].inQuota >= quotas[whitelist[x]].outQuota){
                delinquent[whitelist[x]] = 0;
            }else{
                delinquent[whitelist[x]] += 1;
                if(delinquent[whitelist[x]] >= 7){
                    emit Delinquent(whitelist[x]);
                    delinquent[whitelist[x]] = 0;
                    unwhitelist(x);
                    x--;
                }
            }
        }
        uint256 newQuota = (counterBalance() / 2) / whitelist.length;
        for(uint256 y = 0; y < whitelist.length; y++){
            quotas[whitelist[y]] = Quota(0,0,newQuota);
            emit QuotaIssued(whitelist[y], newQuota);
        }
        lastQuota = block.number;
    }

    function checkQuota(address anAddress) public view returns (uint256, uint256, uint256){
        return (quotas[anAddress].inQuota, quotas[anAddress].outQuota, quotas[anAddress].maxQuota);
    }

    function myQuota() public view returns (uint256, uint256, uint256){
        return checkQuota(msg.sender);
    }

    function removeFromWhitelist(uint256 index) internal {
        if (index >= whitelist.length) return;
        for (uint256 i = index; i<whitelist.length-1; i++){
            whitelist[i] = whitelist[i+1];
        }
        delete whitelist[whitelist.length-1];
        whitelist.length = whitelist.length-1;
    }

}