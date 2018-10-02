pragma solidity ^0.4.24;

interface HourglassInterface {
    function sell(uint256) external;
    function withdraw() external;
    function buy(address referrer) payable external returns (uint256);
    function myTokens() external view returns (uint256);
    function myDividends(bool) external view returns (uint256);
}