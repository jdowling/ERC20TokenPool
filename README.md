# ERC20TokenPool

ERC20TokenPool evenly distributes tokens among shares. The token must implement _at minimum_ `blanceOf` and `transfer` from ERC20 to work with the ERC20TokenPool.

On creation the ERC20TokenPool is given:

* a Token contract address
* the maximum number of available shares (capped at 100)
* the ether cost per share

The ERC20TokenPool owner is able to extract ether that was used to purchase shares by calling `withdrawEther`.

Tokens within the ERC20TokenPool can be even distributed among all shares by calling the `distribute` method. Later each share owner can extract their Tokens from the ERC20TokenPool by calling `withdraw`. Outstanding ERC20TokenPool token allocation balances can be checked using `balanceOf`.

## Dependencies

ERC20TokenPool was developed using [Truffle](https://github.com/ConsenSys/truffle) and depends on [OpenZeppelin](https://github.com/OpenZeppelin/zeppelin-solidity) contracts. I used `testrpc` to run unit tests.
