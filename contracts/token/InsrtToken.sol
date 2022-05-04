// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import { ERC20 } from '@solidstate/contracts/token/ERC20/ERC20.sol';
import { ERC20Metadata } from '@solidstate/contracts/token/ERC20/metadata/ERC20Metadata.sol';

/**
 * @title Insrt Finance governance token
 * @author Insrt Finance
 */
contract InsrtToken is ERC20 {
    constructor(address holder) {
        _mint(holder, 100e6 ether);
    }

    /**
     * @inheritdoc ERC20Metadata
     */
    function name() public pure override returns (string memory) {
        return 'INSRT';
    }

    /**
     * @inheritdoc ERC20Metadata
     */
    function symbol() public pure override returns (string memory) {
        return 'INSRT';
    }

    /**
     * @inheritdoc ERC20Metadata
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
