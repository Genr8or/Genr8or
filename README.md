# Genr8or

A dApp based platform for the monetization of audiences by influencers.

## What's it do?

The platform consists of multiple parts, each of which contribute to a holistic solution for creating open ended fair markets based on sustainable economics:

1. Genr8: An ERC-20 security token backed by ETH, or another ERC-20 token.
2. Genr8or: A factory for the one-step creation and configuration of Genr8 security token markets.
3. Genr8ICO: A refundable fair launch protocol ensuring the proper economic conditions exist for launch.
4. Genr8orICO: A factory for the one-step creation and configuration of Genr8ICOs.
5. Genr8Bonds: A bond market based on Genr8 security tokens with future deliverable guarantees.
6. Genr8orBonds: A factory for the one step creation and configuration of Genr8Bonds.
7. Genr8Futures: An ERC-20 security token for futures with any-time delivery based on the delivery of Genr8Bonds.
8. Genr8orFutures: A factory for the one step creation and configuration of Genr8Futures.
9. Genr8Registry: A registry for the discovery of items 1-8.

## Genr8

Genr8 is an ERC-20 security token, backed 1:1 by it's availalbe counter balance (either ETH or another ERC-20 token).

It's designed to enable investment in an operation which will generate revenue, and share that revenue equally among all investors. It also allows investors to use crowdsourcing of decision making to create additional revenue for participants, with no risk to participants who do not wish to risk at a cost of some of their revenue share.

Security tokens are always redeemable for their backing counter at any time. Buy and sell events are revenue neutral: They don't change the price. Revenue, which is any counter security that enters the contract independant of new investors, is considered 'revenvue' and increases the buy/sell price of the token proportionate to the new amount of funds available.

As a result, the 'price' of the token can only ever go up, since additional counter which arrives in the balance of the contract is then also counted towards the price increase. The number of investors at risk of losing anything are therefore ZERO.

Once the counter has been invested, anyone can submit a "proposal". A proposal is a way to invest the funds in an external source, with the intention of later selling that investment. A proposal is then committed to by investors in the fund, which causes their investment to be spent as part of the execution of the proposal.

A proposal can have and set of conditions for execution, such as an amount that's being invested, or external factors that are invoked through a supplied external contract. Once a proposal has met it's requirement, it can be executed by any committer of it, causing all the committed funds to be spent to the supplied external contract. Committers can then vote to close the propsal, which executes a sell of the committed security, returning a revenue source or realizing a loss for the contract depending on the outcome of the investment.

When a committed proposal is closed for a positive win the revenue is split proportionately in a 90/10% split between the committers of the proposal and ALL the owners of the security. However if it's closed for a negative amount that loss is shared only by the committers. Thus is it the best interest of the committers to only close proposals for a gain, or else they will take the loss.

### How to deploy and use

The costructor accepts the following arguments:
- bytes32 Name: ERC-20 Name
- bytes32 Symbol: ERC-20 Symbol
- uint256 SellRevenuePercent: A number between 0 and 100 for the amount to take from sellers and put towards revenue.
- address Counter: The backing currency, 0x0 for ETH, or the ERC-20 address for ERC-20.
- uint8 Decimals: The number of decimals of the counter: 18 for ETH, possibly something else for an ERC-20.

Once deployed, you can:
- buy (or buyERC20): Buy tokens at the current price, sending counter
- sell: Sell tokens at the current price, receiving counter
- donate: Sends counter which raises the buy and sell price of tokens
- transfer: Sends the tokens somewhere else (ERC-20)
- myTokens: Get your balance
- revenueCost: Compute the revenue cost for a sell
- tokensToCounter/counterToTokens: Compute the exchange rate for counter<->tokens
- createProposal: Create a new proposal
- commit: Commit funds to an unexecuted proposal
- uncommit: Uncommit funds to an unexecuted proposal
- execute: Execute a proposal
- vote: Vote to close out an executed proposal
- close: Close an executed proposal that has reached a majority vote to close

## Genr8or
## Genr8ICO
## Genr8orICO
## Genr8Bonds
## Genr8orBonds
## Genr8Futures
## Genr8orFutures


