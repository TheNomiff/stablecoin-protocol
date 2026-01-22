# DSCEngine

## Overview

DSCEngine is the **core logic contract** of the decentralized stablecoin system.

While the `DecentralizedStableCoin` (DSC) contract only handles:
- Minting
- Burning
- ERC20 behavior

The **DSCEngine** is responsible for:

- Accepting collateral (WETH, WBTC, etc.)
- Tracking user deposits
- Fetching USD prices using Chainlink
- Calculating total collateral value
- Enforcing system safety rules
- Preparing the foundation for minting, burning, and liquidation

In short:

> **DSCEngine = Brain**  
> **DSC = Token**

Users never interact directly with the DSC token.  
All interactions go through the DSCEngine.

---

## Why We Need DSCEngine

A stablecoin system must:

1. Know how much collateral users deposited  
2. Know the USD value of that collateral  
3. Allow only approved tokens  
4. Prevent unsafe minting  
5. Protect the system from risk  

The token contract alone cannot do this.

So we use **DSCEngine** to:

- Enforce rules  
- Track balances  
- Calculate risk  
- Keep the system over-collateralized  

---

## System Flow (How It Works)

1. User deposits collateral (WETH / WBTC)
2. Engine stores the deposit in mappings
3. Engine uses Chainlink to get USD price
4. Engine calculates total USD value
5. Later:
   - Minting
   - Burning
   - Health Factor
   - Liquidation  
   will be built on top of this logic

Right now, this version focuses on the **foundation**.

---

## Contract Structure

The contract is structured in this order:

- Errors  
- State Variables  
- Modifiers  
- Mappings & Arrays  
- Constants  
- Constructor  
- Public Functions  
- Private Functions  
- Getter Functions  

This makes the code clean and readable.

---

# DSCEngine – Function Explanations (WHY + ROLE)

---

## depositCollateral()

### What it does  
Allows a user to deposit approved collateral (like WETH / WBTC) into the system.

### Why we need it  
A stablecoin must be backed by collateral.  
Without collateral deposits:
- No backing  
- No safety  
- No minting possible  

### Role in the system  
This function:
1. Stores how much collateral a user has deposited  
2. Transfers tokens from the user to the engine  
3. Makes the user eligible to mint DSC  

This is the **entry point** of the protocol.

---

## mintDsc()

### What it does  
Mints DSC tokens for the user.

### Why we need it  
Users deposit collateral **to borrow stablecoins**.  
Minting is how they receive DSC.

### Role in the system  
Before minting:
- The user’s debt is updated  
- The Health Factor is checked  

If the user becomes unsafe:
- The transaction reverts  
- No DSC is minted  

This ensures **over-collateralization** and system safety.

---

## _getUsdValue()

### What it does  
Converts a token amount into its USD value using Chainlink price feeds.

### Why we need it  
The protocol works in **USD terms** (stablecoin = $1).  
So we must know:
- How much a user’s collateral is worth in USD  

### Role in the system  
Used for:
- Collateral value calculation  
- Health Factor calculation  
- Risk checks  

Without this function, the system would not know real collateral value.

---

## getAccountCollateralValue()

### What it does  
Calculates the total USD value of all collateral deposited by a user.

### Why we need it  
Users can deposit **multiple tokens** (WETH, WBTC, etc).  
We need a single USD value to measure risk.

### Role in the system  
This function:
1. Loops through all allowed collateral tokens  
2. Gets the user’s deposit for each  
3. Converts each to USD  
4. Adds them together  

This total value is used in Health Factor calculation.

---

## _getAccountInformation()

### What it does  
Returns:
- How much DSC a user has minted  
- How much USD collateral they have  

### Why we need it  
Health Factor needs **both**:
- Debt (DSC minted)  
- Collateral value  

### Role in the system  
This function centralizes user financial data  
so other functions don’t need to repeat logic.

---

## _calculateHealthFactor()

### What it does  
Calculates how safe a user is.

### Formula (Simple Math)
\[ \text{Health Factor} = \frac{\text{Collateral Value} \times \text{Liquidation Threshold}}{\text{Total Debt}} \]
Only **50% of collateral** is considered safe  
to protect against price drops.

### Why we need it  
This prevents:
- Over-minting  
- System insolvency  
- Peg failure  

### Role in the system  
If Health Factor:
- ≥ 1 → User is safe  
- < 1 → User is risky  

If a user has **zero debt**,  
Health Factor = max value (infinite safety).

---

## _healtherFactor()

### What it does  
Calculates a specific user’s Health Factor.

### Why we need it  
Instead of manually passing values every time,  
this function directly gets the user’s risk score.

### Role in the system  
Used internally for:
- Mint safety checks  
- Liquidation checks (future)  

---

## _revertIfHealthFactorIsBroken()

### What it does  
Reverts the transaction if the user becomes unsafe.

### Why we need it  
No unsafe minting should ever happen.

### Role in the system  
Acts as the **safety gate** of the protocol.  
If Health Factor drops below minimum:
- The action is blocked  
- System stays secure  

This single function protects the entire protocol.

---

## Final Summary

Each function exists to enforce one rule:

- Collateral must exist  
- Value must be measured  
- Debt must be tracked  
- Risk must be calculated  
- Unsafe actions must be blocked  

Together, they form the **core safety system** of the stablecoin protocol.
They ensure that the stablecoin remains fully collateralized, secure, and reliable.