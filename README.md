<img width="1494" height="818" alt="image" src="https://github.com/user-attachments/assets/c23576d7-87c8-476e-969a-2390f897173c" />

# JCollateral Smart Contracts

## Project Overview

This repository contains the **smart contracts** for **JCollateral**, a decentralized collateral management and lending protocol.  
The contracts define the core on-chain logic for collateral deposits, borrowing against collateral, managing debt positions, and handling liquidations in a decentralized manner.

These contracts are written in **Solidity** and developed using **Foundry**, a fast and modular toolkit for Ethereum application development.

- **Live Product:** [JCollateral](https://jcollateral.vercel.app/)
- **Frontend using Nextjs:** [JCollateral Frontend](https://github.com/JasonTongg/JCollateral_Frontend)

## Protocol Summary

JCollateral enables users to:

- Deposit supported collateral assets
- Borrow against deposited collateral
- Repay borrowed assets to unlock collateral
- View and manage positions on-chain
- Enable automated or incentive-based liquidation for under-collateralized positions

This repository includes all protocol logic required to enforce safe, composable, and permissionless lending operations.

## Contracts Description

### `Jcol.sol`

**Role:** Core token and system state contract

`Jcol.sol` acts as the central contract of the protocol. It is responsible for:

- Managing the protocol’s base token logic
- Tracking balances and internal accounting
- Acting as a shared dependency for lending and exchange operations
- Serving as the primary contract referenced by other modules

This contract provides the foundational state that other contracts rely on to execute lending and exchange logic safely.

### `Lending.sol`

**Role:** Collateralized lending and borrowing engine

`Lending.sol` implements the core **collateralized lending logic** of JCollateral. Its responsibilities include:

- Accepting collateral deposits (e.g. ETH)
- Allowing users to borrow against deposited collateral
- Enforcing collateralization rules
- Handling repayment flows
- Tracking user debt positions

This contract ensures users remain sufficiently collateralized and prevents unsafe borrowing behavior.

### `JcolDEX.sol`

**Role:** Internal DEX / swap mechanism (testing & demo)

`JcolDEX.sol` provides a **simple decentralized exchange mechanism** used within the JCollateral ecosystem. It is primarily intended for:

- Swapping between protocol assets
- Simulating market activity
- Supporting testing and frontend demonstrations

This contract is **not designed to replace a production-grade AMM**, but rather to support local liquidity flows within the protocol.

### `MovePrice.sol`

**Role:** Price movement and oracle simulation

`MovePrice.sol` is used to **manually or programmatically adjust prices** within the system. Its primary purpose is:

- Simulating market price changes
- Testing liquidation scenarios
- Demonstrating how price movements affect collateral ratios

This contract is especially useful for development, testing, and educational demonstrations where external oracle dependencies are intentionally avoided.

## Protocol Flow Summary

1. Users deposit collateral through `Lending.sol`
2. Borrowing power is calculated based on system pricing
3. Prices can be adjusted using `MovePrice.sol`
4. Assets can be swapped internally using `JcolDEX.sol`
5. Repayments and collateral withdrawals are enforced by lending rules


## Technology Stack

- **Language:** Solidity ^0.8.x
- **Development Framework:** Foundry
- **Testing:** Forge
- **Deployment:** Forge scripts
- **Network:** ETH Sepolia

## Security Notes
- This project is not audited
- Intended for testing, learning, and demonstration
- Do not deploy to mainnet without a full audit
- Price logic is intentionally simplified

## Author  

**Jason Tong**  

- **Product:** [JCollateral](https://jcollateral.vercel.app/)
- **GitHub:** [JasonTongg](https://github.com/JasonTongg).
- **Linkedin:** [Jason Tong](https://www.linkedin.com/in/jason-tong-42600319a/).
