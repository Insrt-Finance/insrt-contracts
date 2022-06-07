// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { SolidStateERC20 } from '@solidstate/contracts/token/ERC20/SolidStateERC20.sol';

contract SolidStateERC20Mock is SolidStateERC20 {
    function __mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function __burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}
