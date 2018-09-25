pragma solidity ^0.4.24;

interface ApproveAndCallFallBack{
    function receiveApproval(address, uint256, address, bytes) external;
}