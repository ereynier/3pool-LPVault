# Vault 3Pool for charity

The Vault smart contract is a liquidity management solution that allows users to deposit DAI tokens into the Curve 3pool liquidity pool and receive VAULT tokens in exchange. This contract also provides the ability to withdraw DAI in exchange for VAULT tokens, harvest CRV tokens for charity, and configure various parameters.

## Key Features

- **DAI Deposit:** Users can deposit DAI into the vault in exchange for VAULT tokens representing their liquidity pool participation.

- **DAI Withdrawal:** Users can withdraw DAI in exchange for the VAULT tokens they hold. VAULT tokens are burned, 3CRV tokens are withdrawn from the Curve gauge, and exchanged for DAI in the Curve pool.

- **CRV Harvest:** Any user can periodically harvest CRV tokens. 1% of the harvested CRV goes to the caller, 1% goes to the contract owner, and 98% goes to a designated beneficiary address (charity).

- **Slippage Adjustment:** The contract owner can set the slippage tolerance level when adding liquidity to the Curve pool.

- **Beneficiary Address Configuration:** The contract owner can set the address of the charity organization to receive a portion of the CRV rewards.

## Usage

1. **DAI Deposit:** Users can call the `deposit` function to deposit DAI and receive VAULT tokens in exchange.

2. **DAI Withdrawal:** Users can call the `withdraw` function to withdraw DAI in exchange for the VAULT tokens they hold.

3. **CRV Harvest:** All users can harvest CRV tokens by calling the `harvest` function.

4. **Slippage Adjustment:** The contract owner can adjust the slippage tolerance using the `setSlippage` function.

5. **Beneficiary Address Configuration:** The contract owner can set the charity organization's address using the `setCharity` function.

## Contracts and Interfaces

- The contract uses interfaces to interact with other contracts, including the Curve pool, Curve gauge, and minter.

## License

See [LICENSE](LICENSE).

---

For more information on using and deploying this contract, please refer to the associated documentation.


## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test --fork-url <your_etheteum_mainnet_rpc_url>
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
