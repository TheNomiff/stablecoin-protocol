# Decentralized Stablecoin Protocol (DSC)

This project is a **decentralized, over-collateralized stablecoin system** inspired by MakerDAO / DAI.

The system allows users to:
- Deposit crypto collateral (like WETH / WBTC)
- Mint a USD-pegged stablecoin (DSC)
- Maintain safety through Health Factor checks

The protocol is designed to stay **solvent, secure, and over-collateralized** at all times.

---

## Project Structure
The protocol consists of two main smart contracts:
1. **DecentralizedStableCoin (DSC)** - An ERC20-compatible stablecoin contract responsible for minting and burning DSC tokens.
2. **DSCEngine** - The core logic contract that manages collateral deposits, price feeds
3. health factor calculations, and enforces system safety rules.
Users interact only with the DSCEngine contract, which in turn manages the DSC token.
---

## Key Features
- **Over-Collateralization**: Users must deposit more value in collateral than the DSC they mint.
- **Health Factor**: A metric to ensure users maintain sufficient collateralization.
- **Chainlink Price Feeds**: Real-time price data for accurate collateral valuation.
- **Separation of Concerns**: DSC handles token logic, while DSCEngine manages financial logic.
- **Custom Errors**: Gas-efficient error handling for better performance.
- **Security Focused**: Designed with security best practices to protect user funds.
- **Extensive Testing**: Comprehensive unit tests to ensure reliability and correctness.
- **Documentation**: Clear and detailed documentation for developers and users.