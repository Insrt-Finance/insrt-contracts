// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';
import { IDiamondLoupe } from '@solidstate/contracts/proxy/diamond/IDiamondLoupe.sol';

/**
 * @title Upgradeable proxy with externally controlled Index implementation
 */
contract IndexProxy is Proxy {
    address private immutable INDEX_DIAMOND;

    constructor(address indexDiamond) {
        INDEX_DIAMOND = indexDiamond;
    }

    /**
     * @inheritdoc Proxy
     * @notice fetch logic implementation address from external diamond proxy
     */
    function _getImplementation() internal view override returns (address) {
        return IDiamondLoupe(INDEX_DIAMOND).facetAddress(msg.sig);
    }
}
