pragma solidity ^0.4.24;
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Genr8Registry is Ownable {

    event RegistryEntry(
        bytes32 namespace,
        bytes32 key,
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
    mapping(bytes32 => bool) internal namespaceRegistry;
    mapping(bytes32 => mapping(bytes32=>address)) registry;
    bytes32[] namespaceList;
    mapping(bytes32 => address[]) keyList;
    mapping(address => bool) whitelist;
    mapping(address => bool) administrator;

    function setAdministrator(address who, bool status) isAdmin public {
        administrator[who] = status;
    }

    function setWhitelist(address who, bool status) isAdmin public {
        whitelist[who] = status;
    }

    function setRegistry(bytes32 namespace, bytes32 key, address value) isWhitelisted public {
        registry[namespace][key] = value;
        if(!namespaceRegistry[namespace]){
            namespaceRegistry[namespace] = true;
            namespaceList.push(namespace);
        }
        keyList[key].push(value);
        emit RegistryEntry(namespace, key, value, msg.sender);
    }

    function lookUp(bytes32 namespace, bytes32 key) public view returns(address){
        return registry[namespace][key];
    }

    function listNamespaces() public view returns(bytes32[]){
        return namespaceList;
    }

    function listKeys(bytes32 key) public view returns(address[]){
        return keyList[key];
    }

    function isNamespaceInUse(bytes32 namespace) public view returns(bool){
        return namespaceRegistry[namespace];
    }
}