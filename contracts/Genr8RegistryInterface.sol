pragma solidity ^0.4.24;

interface Genr8RegistryInterface {
    function setRegistry(string, string, address) external;
    function lookUp(string, string) external view returns(address);   
}