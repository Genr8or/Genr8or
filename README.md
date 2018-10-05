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

### Genr8

Genr8 is an ERC-20 security token, backed 1:1 by it's availalbe counter balance (either ETH or another ERC-20 token).

Security tokens are always redeemable for their backing counter at any time, minus an optional fee that can be configured at creation. Buy events are revenue neutral: They don't change the price. Sell events cost an optional percentage, which is put towards 'revenue' for the security token; When someone sells, an amount of counter proportionate to their ownership in the total token supply, multiplied by the optional revenue percent, remains left behind in the balance. This increases the buy, and sell price proportionate to the new ration of token supply to balance.

As a result, the 'price' of the token can only ever go up. Any additional counter which arrives in the balance of the contract is then also counted towards the price increase. The number of investors at risk of losing anything are therefore limited in their loss to the percentage of the revenue amount, and they are themselves limited to a maximum of the cost of selling.

Let's use an example of 10%:

If 100 people invest 1 ETH each into a 10% revenue contract, then all of them turn around and sell again, only the first 10 will incur a loss, with the 11th person actually breaking even. The first person who sells will incur the most loss, a full 10% loss of their investment, while everyone after them will lose less, and everyone after the 11th person will actually make money, with the last person to sell making the most. *This is, of course, stupid. It represents the worst case scenario.*

If, however, building on this same example, instead of everyone selling right away, everyone holds, and then 10% of the balance (10 ETH) in 'revenue' arrives in the contract, then everyone can sell at a gain, save the first person who sells who breaks even. Anything more than 10 ETH and everyone walks away with a gain.

Of coures the selling fee is also optional: You can have 0 revenue on sell, making all buys and sells revenue neutral, and depend entirely on external revenue.

From this example, is clear to see that the way to effectively make sure everyone comes out ahead is to ensure a steady supply of *external revenue* for the security. If an investor is investing in this type of security, it's expected that they are speculating on the revenue stream being bigger than the sell percentage of the contract balance, or that there is no sell fee. It is *STRONGLY SUGGESTED* that these only be deployed with the expectation that an additional revenue source will deposit counter in the contract *independant of selling fee* if these are to be economically viable long term, or else limit investors risk by configuring it with *no selling fee  (0)*.

#### How to deploy and use

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

### Genr8or
### Genr8ICO
### Genr8orICO
### Genr8Bonds
### Genr8orBonds
### Genr8Futures
### Genr8orFutures


