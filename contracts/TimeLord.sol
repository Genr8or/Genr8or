pragma solidity ^0.4.24;
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./LeadHandsInterface.sol";
import "./HourglassInterface.sol";
import "./MintableBurnableERC20Token.sol";

/* ================================================================================================ *
 * ================================================================================================ *
 * ================================================================================================ *
 *                                                                                                  *
 *            __            __    __         _                                       __             *
 *        ___/ /___  __ __ / /   / /____    (_)___    ___   ____ ___  ___ ___  ___  / /_ ___        *
 *       / _  // _ \/ // // _ \ / // __/_  / // _ \  / _ \ / __// -_)(_-</ -_)/ _ \/ __/(_-<        *
 *       \_,_/ \___/\_,_//_.__//_//_/  (_)/_/ \___/ / .__//_/   \__//___/\__//_//_/\__//___/        *
 *                                                 /_/                                              *
 *                                                                                                  *
 *                                                                                                  *
 *                                                                                                  *
 *                      _____                   _    _                 _                            *
 *                     |_   _|                 | |  | |               | |                           *
 *                       | |  _ __ ___  _ __   | |__| | __ _ _ __   __| |___                        *
 *                       | | | '__/ _ \| '_ \  |  __  |/ _` | '_ \ / _` / __|                       *
 *                      _| |_| | | (_) | | | | | |  | | (_| | | | | (_| \__ \                       *
 *                     |_____|_|  \___/|_| |_| |_|  |_|\__,_|_| |_|\__,_|___/                       *
 *                                                                                                  *
 *                                                                                                  *
 *   ::::::::::: ::::::::::: ::::     :::: :::::::::: :::        ::::::::  :::::::::  :::::::::     *
 *       :+:         :+:     +:+:+: :+:+:+ :+:        :+:       :+:    :+: :+:    :+: :+:    :+:    *
 *       +:+         +:+     +:+ +:+:+ +:+ +:+        +:+       +:+    +:+ +:+    +:+ +:+    +:+    *
 *       +#+         +#+     +#+  +:+  +#+ +#++:++#   +#+       +#+    +:+ +#++:++#:  +#+    +:+    *
 *       +#+         +#+     +#+       +#+ +#+        +#+       +#+    +#+ +#+    +#+ +#+    +#+    *
 *       #+#         #+#     #+#       #+# #+#        #+#       #+#    #+# #+#    #+# #+#    #+#    *
 *       ###     ########### ###       ### ########## ########## ########  ###    ### #########     *
 *                                                                                                  *
 *                                                                                                  *
 *                                         _n____n__                                                *
 *                                        /         \---||--<                                       *
 *                                       /___________\                                              *
 *                                       _|____|____|_                                              *
 *                                       _|____|____|_                                              *
 *                                        |    |    |                                               *
 *                                       --------------                                             *
 *                                       | || || || ||\                                             *
 *                                       | || || || || \++++++++------<                             *
 *                                       ===============                                            *
 *                                       |   |  |  |   |                                            *
 *                                      (| O | O| O| O |)                                           *
 *                                      |   |   |   |   |                                           *
 *                                     (| O | O | O |  O |)                                         *
 *                                      |   |   |    |    |                                         *
 *                                    (| O |  O |  O  | O  |)                                       *
 *                                     |   |    |     |    |                                        *
 *                                    (| O |  O  |   O |  O |)                                      *
 *                                   /========================\                                     *
 *                                   \vvvvvvvvvvvvvvvvvvvvvvvv/                                     *
 *                                                                                                  *
 * ================================================================================================ *
 * ================================================================================================ *
 * ================================================================================================ *
 */


contract TimeLord is Ownable, MintableBurnableERC20Token {
    
    event FuturesCreated(address creator, uint256 amount);
    event FuturesDestroyed(address destroyer, uint256 amount, uint256 amountReemed);

    LeadHandsInterface leadHands;
    HourglassInterface hourglass;

    uint256 public paidOut; // How much total ETH has been paid out to users.

    /**
     * Constructor
     */
    constructor(address leadHandsAddress, address hourglassAddress) public {
        leadHands = LeadHandsInterface(leadHandsAddress);
        hourglass = HourglassInterface(hourglassAddress);
    }
    
    function() payable public {
    }

    function purchaseFutures() public payable {
        uint256 oldBalance = address(this).balance - msg.value;
        leadHands.purchaseBond.value(msg.value)();
        uint256 newBalance = address(this).balance;
        uint256 remainder = newBalance - oldBalance;
        if(remainder > 0){
            msg.sender.transfer(remainder);
        }
        uint256 amountToCredit = counterToTokens(msg.value);
        if(amountToCredit > msg.value){
            amountToCredit = msg.value;
        }
        mint(msg.sender, amountToCredit);
        emit FuturesCreated(msg.sender, amountToCredit);
    }

    function redeemFutures(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount);
        uint256 amountToSend = tokensToCounter(amount);
        paidOut += amountToSend;
        msg.sender.call.value(amountToSend).gas(1000000)();
        burn(msg.sender, amount);
        emit FuturesDestroyed(msg.sender, amount, amountToSend);
    }

    /**
     * Convert X tokens to Y counter
     */
    function tokensToCounter(uint256 anAmount) public view returns(uint256) {
        if(totalSupply() == 0){
            return anAmount;
        }
        return SafeMath.div(SafeMath.mul(SafeMath.div(SafeMath.mul(totalSupply(), 100), address(this).balance), anAmount),100);
    }
    
    /**
     * Convert X counter to Y tokens
     */
    function counterToTokens(uint256 anAmount) public view returns(uint256) {
        if(totalSupply() == 0){
            return anAmount;
        }
        return SafeMath.mul(SafeMath.div(anAmount, SafeMath.div(SafeMath.mul(totalSupply(), 100), address(this).balance), 100);
    }

    function totalPaid() public view returns (uint256){
        return paidOut;
    }
    

}