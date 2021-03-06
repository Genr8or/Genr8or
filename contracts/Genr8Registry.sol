pragma solidity ^0.4.24;
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Genr8Registry is Ownable {

    event RegistryEntry(
        string namespace,
        string key,
        address value,
        address setter
    );

    modifier isAdmin() {
        require(administrator[msg.sender] || owner == msg.sender);
        _;
    }

    modifier isWhitelisted() {
        require(whitelist[msg.sender] || administrator[msg.sender] || owner == msg.sender);
        _;
    }
    mapping(string => bool) internal namespaceRegistry;
    mapping(string => mapping(string=>address)) registry;
    string[] namespaceList;
    mapping(string => address[]) keyList;
    mapping(address => bool) whitelist;
    mapping(address => bool) administrator;

    function setAdministrator(address who, bool status) isAdmin public {
        administrator[who] = status;
    }

    function setWhitelist(address who, bool status) isAdmin public {
        whitelist[who] = status;
    }

    function setRegistry(string namespace, string key, address value) isWhitelisted public {
        registry[namespace][key] = value;
        if(!namespaceRegistry[namespace]){
            namespaceRegistry[namespace] = true;
            namespaceList.push(namespace);
        }
        keyList[key].push(value);
        emit RegistryEntry(namespace, key, value, msg.sender);
    }

    function lookUp(string namespace, string key) public view returns(address){
        return registry[namespace][key];
    }

    function listKeys(string key) public view returns(address[]){
        return keyList[key];
    }

    function isNamespaceInUse(string namespace) public view returns(bool){
        return namespaceRegistry[namespace];
    }
}