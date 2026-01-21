# DecentralizedStableCoin (DSC)

## Overview

DecentralizedStableCoin (DSC) is an ERC20-compatible stablecoin designed to be pegged to the US Dollar (USD).  
It is part of a decentralized stablecoin system where minting and burning are fully controlled by a separate contract called **DSCEngine**.

This contract does **not** handle:
- Collateral logic  
- Price feeds  
- Health factor  
- Liquidation  

Its only responsibility is to:
- Mint DSC tokens  
- Burn DSC tokens  
- Follow ERC20 standards  

---

## Purpose of This Contract

The goal of this contract is to keep the token logic **simple and secure**.

All financial and risk-related logic is handled by **DSCEngine**, while this contract only manages:

- Token supply  
- User balances  
- Minting and burning  

This separation improves:
- Security  
- Maintainability  
- Testability  

---

## Design Philosophy

| Component | Responsibility |
|----------|----------------|
| DecentralizedStableCoin | ERC20 token logic |
| DSCEngine | Collateral, minting rules, liquidation |
| User | Interacts only with DSCEngine |

The token contract is intentionally kept "dumb".

---

## Key Features

- ERC20 compliant  
- Burnable tokens  
- Controlled minting  
- Only the owner (DSCEngine) can mint or burn  
- Custom errors for gas efficiency  

---

## Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    error DecentralizedStableCoin__MustBeMoreThanZero();
    error DecentralizedStableCoin__BurnAmountExeedsBalance();
    error DecentralizedStableCoin__NotZeroAddress();

    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);

        if (_amount == 0) revert DecentralizedStableCoin__MustBeMoreThanZero();
        if (_amount > balance) revert DecentralizedStableCoin__BurnAmountExeedsBalance();

        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        if (_to == address(0)) revert DecentralizedStableCoin__NotZeroAddress();
        if (_amount == 0) revert DecentralizedStableCoin__MustBeMoreThanZero();

        _mint(_to, _amount);
    }
}
```