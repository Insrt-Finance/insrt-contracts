// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import { UpgradeableProxy } from '@solidstate/contracts/proxy/upgradeable/UpgradeableProxy.sol';

/**
 * @title xINSRT Token Proxy
 * @author Insrt Finance
 */
contract StakedInsrtTokenProxy is UpgradeableProxy {
    constructor(address implementation) {
        _setImplementation(implementation);
    }
}
