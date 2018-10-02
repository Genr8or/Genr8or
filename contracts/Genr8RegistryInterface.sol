pragma solidity ^0.4.24;

interface Genr8RegistryInterface {
    function setRegistry(bytes32, bytes32, address) external;
    function lookUp(bytes32, bytes32) external view returns(address);   
}