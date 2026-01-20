// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecentralizedStableCoin
 * @author Nomiff
 *
 * @notice ERC20 stablecoin pegged to USD
 * @notice Minting and burning are controlled by DSCEngine
 * @dev Uses OpenZeppelin ERC20Burnable and Ownable
 */

contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    ///////////////
    /// Errors ///
    //////////////
    error DecentralizedStableCoin__MustBeMoreThanZero();
    error DecentralizedStableCoin__BurnAmountExeedsBalance();
    error DecentralizedStableCoin__NotZeroAddress();

    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);

        if (_amount <= 0) revert DecentralizedStableCoin__MustBeMoreThanZero();
        if (_amount > balance)
            revert DecentralizedStableCoin__BurnAmountExeedsBalance();

        super.burn(_amount);
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) revert DecentralizedStableCoin__NotZeroAddress();
        if (_amount <= 0) revert DecentralizedStableCoin__MustBeMoreThanZero();

        _mint(_to, _amount);

        return true;
    }
}
