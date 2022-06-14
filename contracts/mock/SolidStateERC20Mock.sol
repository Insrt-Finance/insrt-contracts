// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { SolidStateERC20 } from '@solidstate/contracts/token/ERC20/SolidStateERC20.sol';
import { ERC20MetadataStorage } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol';

/**
 * @title Mock ERC20 contract used for testing
 * @dev exposes mint/burn functions for testing purposes
 */
contract SolidStateERC20Mock is SolidStateERC20 {
    using ERC20MetadataStorage for ERC20MetadataStorage.Layout;

    constructor(string memory name, string memory symbol) {
        ERC20MetadataStorage.Layout storage l = ERC20MetadataStorage.layout();

        l.name = name;
        l.symbol = symbol;
        l.decimals = 18;
    }

    function __mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function __burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}
