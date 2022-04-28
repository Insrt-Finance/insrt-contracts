// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';
import { IDiamondLoupe } from '@solidstate/contracts/proxy/diamond/IDiamondLoupe.sol';
import { ERC4626BaseStorage } from '@solidstate/contracts/token/ERC4626/base/ERC4626BaseStorage.sol';

/**
 * @title Upgradeable proxy with externally controlled Index implementation
 */
contract IndexProxy is Proxy {
    address private immutable INDEX_DIAMOND;

    constructor(address indexDiamond, address investmentPool) {
        INDEX_DIAMOND = indexDiamond;

        ERC4626BaseStorage.layout().asset = investmentPool;
    }

    /**
     * @inheritdoc Proxy
     * @notice fetch logic implementation address from external diamond proxy
     */
    function _getImplementation() internal view override returns (address) {
        return IDiamondLoupe(INDEX_DIAMOND).facetAddress(msg.sig);
    }
}
