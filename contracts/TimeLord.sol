pragma solidity ^0.4.24;
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./LeadHandsInterface.sol";
import "./HourglassInterface.sol";
import "./BackedERC20Token.sol";

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


contract TimeLord is Ownable, BackedERC20Token {
    
    event FuturesCreated(address creator, uint256 amount, uint256 amountOfInvesment);
    event FuturesDestroyed(address destroyer, uint256 amount, uint256 amountReemed);

    LeadHandsInterface leadHands;
    HourglassInterface hourglass;
    
    // How much total ETH has been paid out to users.
    uint256 public paidOut; 

    /**
     * Constructor
     */
    constructor(string name, string symbol, address leadHandsAddress, address hourglassAddress) BackedERC20Token(name, symbol, 18, 0x0, 1000) public {
        leadHands = LeadHandsInterface(leadHandsAddress);
        hourglass = HourglassInterface(hourglassAddress);
    }
    
    /**
     * Default payable function. Any revenue will just increate the redemption price for all futures.
     */
    function() payable public {
    }

    /**
     * Purchase futures by investing some ETH.
     */
    function purchaseFutures() public payable {
        //Get the balance of the contract, minus our investment
        uint256 oldBalance = address(this).balance.sub(msg.value);
        //Spend our investment
        leadHands.purchaseBond.value(msg.value)();
        //Get the new balance, post investment;
        uint256 newBalance = address(this).balance;
        //Compute the remaining investment
        uint256 remainder = newBalance.sub(oldBalance);
        //If we still have remaining investment
        if(remainder > 0){
            //Send the remainder back.
            msg.sender.transfer(remainder);
        }
        //Compute the actual investment
        uint256 actualInvestment = msg.value.sub(remainder);
        //Compute how much to give them.
        uint256 amountToCredit = counterToTokens(actualInvestment);
        //If the contract is in the positive
        if(amountToCredit > actualInvestment){
            //Only credit them the amount of their investment (prevents draining when it's revenue negative)
            amountToCredit = actualInvestment;
        }
        //Give them their tokens
        mint(msg.sender, amountToCredit);
        //Log the event
        emit FuturesCreated(msg.sender, amountToCredit, actualInvestment);
    }

    /**
     * Enact delivery of your futures, redeeming them for their available value.
     */
    function redeemFutures(uint256 amount) public {
        //Make sure they have enough to redeem
        require(balanceOf(msg.sender) >= amount);
        //Compute how much they're worth
        uint256 amountToSend = tokensToCounter(amount);
        //Keep the total of how much we have sent for bookkeeping
        paidOut += amountToSend;
        //Send them their redemption value
        msg.sender.call.value(amountToSend).gas(1000000)();
        //Burn their tokens
        burn(msg.sender, amount);
        //Log the event
        emit FuturesDestroyed(msg.sender, amount, amountToSend);
    }

    function totalPaid() public view returns (uint256){
        return paidOut;
    }


}