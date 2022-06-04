// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { SolidStateERC20 } from '@solidstate/contracts/token/ERC20/SolidStateERC20.sol';
import { ERC20MetadataStorage } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol';

contract SolidStateERC20Mock is SolidStateERC20 {
    using ERC20MetadataStorage for ERC20MetadataStorage.Layout;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 supply
    ) {
        ERC20MetadataStorage.Layout storage l = ERC20MetadataStorage.layout();

        l.setName(name);
        l.setSymbol(symbol);
        l.setDecimals(decimals);

        _mint(msg.sender, supply);
    }

    function __mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function __burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}
