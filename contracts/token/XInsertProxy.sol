// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import { UpgradeableProxy } from '@solidstate/contracts/proxy/upgradeable/UpgradeableProxy.sol';

/**
 * @title Insert Finance XInsert Proxy
 * @author Insert Finance
 * @notice Proxy for XInsert implementation
 */

contract XInsertProxy is UpgradeableProxy {
    constructor(address implementation) {
        _setImplementation(implementation);
    }
}
