# Genr8or

A dApp based platform for the monetization of audiences by influencers through the creation of investor products.

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

The point of a Genr8 is to provide funding to opportunities, with the expectation of a return that's made available to investors. It's designed to enable investment in an operation which will generate revenue, and share that revenue equally among all investors. It also allows investors to use crowdsourcing of decision making to create additional revenue for participants, with no risk to participants who do not wish to risk at a cost of some of their revenue share.

Security tokens are always redeemable for their backing counter at any time. Buy and sell events are revenue neutral: They don't change the price. Revenue, which is any counter security that enters the contract independant of new investors, is considered 'revenvue' and increases the buy/sell price of the token proportionate to the new amount of funds available.

## Index vs Hedge Fund Mode

Genr8 funds can operate in one of two modes: Index fund, or Hedge fund mode.

When a Genr8 is operating in index fund mode, a set of external opportunities is given access to the funds in the contract via a daily quota with the expectation that they will return more to the fund over time than what they take. Investors can vote to change the parameters of the contract, including what opportunities are being 'indexed', allowing for investors to add or remove new opportunities that they approve, and change the rules that govern those opportunitie's bankrolls.

When a Genr8 is configured in hedge fund mode, the owner of the contract can submit a proposal to fund a specific opportunity, and investors can choose to 'fund' that proposal. When that proposal gives a return, a preconfigured amount amount is split between those who invested in the proposal, and the remainder is used to increase the price of issuing new tokens.

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

## Genr8or

A factory for creating new Genr8s.

## Genr8ICO

A ICO for doing a fair launch of a Genr8.

ICOs are:
- Secure: The users funds are secured by the contract at all times.
- Refundable: Prior to launch, a user can always get their funds back.
- Configurable: The soft, hard, and time cap are all configured by the user, allowing for long running ICO's which do not launch even after reaching their funding goal until a date in the future. Even the counter accepted can be ETH, or ERC-20 based.
- ERC-20/Exchange ready: Since ICO investment represents future ownership of the token backed by the investment, the ERC-20 tokens can be traded on exchanges ahead of the ICO launch, allowing for ICOs valuations beyond their hard cap on the secondary market prior to launch.

## Genr8orICO

A Factory for creating new Genr8ICOs.

## Genr8Bonds

A ERC-20 bond with a delivery based upon increased valuation of a Genr8.

When a bond is purchased, it purchases an underlying security, such as a Genr8 configured in Hedge or Index fund mode. At that time, the user enters a FIFO queue to receive their investment back multiplied by a constant. Since Genr8 tokens have a valuation that is determinable on-chain, upon demand a user can sell 1/2 the profitable portion of the 

## Genr8orBonds
## Genr8Futures
## Genr8orFutures


