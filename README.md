# Writeup

- initially, the Setup contract has 1050 ether
- create a new token with a total supply of 1,000,000
- create a uniswap pool with the new token and weth
- create a lender pool from the uniswap pool
- give lender contract 500,000 token
- give the uniswap pool 25 weth and 500 token as the initial liquidity
- deposits 25 weth into the lender contract
- borrows 250,000 tokens from the lender contract

## Install

```bash
npm install
```

## Testing

### Live

Edit `truffle-config.js` then run the following

```bash
truffle test
```

### Local

Edit `truffle-config.js` then run the following

```bash
ganache-cli -f https://mainnet.infura.io/v3/a84b538abf714818b3662cd1fcd7c530 -u "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2" -u "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f" -p 7545 --defaultBalanceEther 1000000

truffle test

truffle debug <tx_hash>
```

- c: continue to the error line
- n: next line
- t <tx_hash>
- T: unload current tx
- r: reset

## Debug

- Error: Returned error: Returned error: project ID does not have access to archive state
  - Solution: restart local private blockchain
- If encountered "No source code found" in truffle debug, restart ganache and try everything again.

## Support

Chat: https://gitter.im/ConsenSys/truffle
