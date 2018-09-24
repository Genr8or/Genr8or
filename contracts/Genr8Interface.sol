pragma solidity ^0.4.24;

interface Genr8Interface {
    function setName(bytes32 newName) external;
    function setSymbol(bytes32 newSymbol) external;
    function setCounter(address newCounter) external;
    function setDecimals(bytes8 newDecimals) external;
    function setSellRevenuePercent(uint256 _sellRevenuePercent, uint256 _percision) external;
    function buy() external payable returns(uint256);
    function buyERC20(uint256 amount) external returns(uint256);
    function donate() payable external;
    function sell(uint256 amountOfTokens) external returns(uint256);
    function counterBalance() external view returns(uint256);
    function name() external view returns(bytes32);
    function symbol() external view returns(bytes32);
    function decimals() external view returns(uint8);
    function sellRevenuePercent() external view returns (uint256, uint256);
    function myTokens() external view returns(uint256);
    function tokensToCounter(uint256 anAmount) external view returns(uint256);
    function counterToTokens(uint256 anAmount) external view returns(uint256);
    function revenueCost(uint256 anAmount) external view returns(uint256);   
}