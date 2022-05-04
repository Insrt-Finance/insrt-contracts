// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';
import { IDiamondLoupe } from '@solidstate/contracts/proxy/diamond/IDiamondLoupe.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { ERC4626BaseStorage } from '@solidstate/contracts/token/ERC4626/base/ERC4626BaseStorage.sol';

import { IInvestmentPoolFactory } from '../balancer/IInvestmentPoolFactory.sol';

/**
 * @title Upgradeable proxy with externally controlled Index implementation
 */
contract IndexProxy is Proxy {
    address private immutable INDEX_DIAMOND;

    constructor(
        address indexDiamond,
        address investmentPoolFactory,
        IERC20[] memory tokens,
        uint256[] memory weights
    ) {
        INDEX_DIAMOND = indexDiamond;

        // TODO: difference between owner and assetManagers?
        address[] memory assetManagers = new address[](1);
        assetManagers[0] = address(this);

        // deploy investment pool and store as base asset

        ERC4626BaseStorage.layout().asset = IInvestmentPoolFactory(
            investmentPoolFactory
        ).create(
                // TODO: metadata naming conventions?
                'TODO: name',
                'TODO: symbol',
                tokens,
                weights,
                assetManagers,
                // TODO: swapFeePercentage?
                0,
                address(this),
                // TODO: implications of swapEnabledOnStart?
                true
            );
    }

    /**
     * @inheritdoc Proxy
     * @notice fetch logic implementation address from external diamond proxy
     */
    function _getImplementation() internal view override returns (address) {
        return IDiamondLoupe(INDEX_DIAMOND).facetAddress(msg.sig);
    }
}
