// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { SafeOwnable } from '@solidstate/contracts/access/SafeOwnable.sol';

import { IndexProxy } from './IndexProxy.sol';
import { IndexDiamond } from './IndexDiamond.sol';

/**
 * @title Index management contract
 */
contract IndexManager is SafeOwnable {
    address public immutable INDEX_DIAMOND;

    constructor() {
        IndexDiamond indexDiamond = new IndexDiamond();
        // TODO: set diamond owner
        INDEX_DIAMOND = address(indexDiamond);
    }

    function deployIndexProxy()
        external
        onlyOwner
        returns (address deployment)
    {
        deployment = address(new IndexProxy(INDEX_DIAMOND));
    }
}
