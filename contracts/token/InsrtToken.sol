// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import { ERC20 } from '@solidstate/contracts/token/ERC20/ERC20.sol';
import { ERC20MetadataInternal } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataInternal.sol';

/**
 * @title Insrt Finance governance token
 * @author Insrt Finance
 */
contract InsrtToken is ERC20 {
    constructor(address holder) {
        _mint(holder, 100e6 ether);
    }

    /**
     * @inheritdoc ERC20MetadataInternal
     */
    function _name() internal pure override returns (string memory) {
        return 'INSRT';
    }

    /**
     * @inheritdoc ERC20MetadataInternal
     */
    function _symbol() internal pure override returns (string memory) {
        return 'INSRT';
    }

    /**
     * @inheritdoc ERC20MetadataInternal
     */
    function _decimals() internal pure override returns (uint8) {
        return 18;
    }
}
