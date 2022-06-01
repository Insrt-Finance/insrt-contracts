// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

//Cannot import contracts from balancer-labs, hence new interfaces. Delete comment code once confirmed.
//import { IVault } from '@balancer-labs/v2-vault/contracts/interfaces/IVault.sol';
import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';
import { IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { ERC4626BaseStorage } from '@solidstate/contracts/token/ERC4626/base/ERC4626BaseStorage.sol';

import { IInvestmentPoolFactory } from '../balancer/IInvestmentPoolFactory.sol';
import { IInvestmentPool } from '../balancer/IInvestmentPool.sol';
import { IndexStorage } from './IndexStorage.sol';

/**
 * @title Upgradeable proxy with externally controlled Index implementation
 */
contract IndexProxy is Proxy {
    address private immutable INDEX_DIAMOND;

    constructor(
        address indexDiamond,
        address investmentPoolFactory,
        IERC20[] memory tokens,
        uint256[] memory weights,
        uint256 id,
        uint16 exitFee
    ) {
        INDEX_DIAMOND = indexDiamond;

        IndexStorage.Layout storage indexLayout = IndexStorage.layout();
        ERC4626BaseStorage.Layout storage vaultLayout = ERC4626BaseStorage
            .layout();

        // deploy investment pool and store as base asset

        vaultLayout.asset = IInvestmentPoolFactory(investmentPoolFactory)
            .create(
                // TODO: metadata naming conventions?
                'TODO: name',
                'TODO: symbol',
                tokens,
                weights,
                0.02 ether, // swapFeePercentage: 2%
                address(this),
                // TODO: implications of swapEnabledOnStart?
                true,
                // TODO: managementSwapFeePercentage?
                0
            );

        indexLayout.id = id;
        indexLayout.exitFee = exitFee;
        indexLayout.poolId = IInvestmentPool(vaultLayout.asset).getPoolId(); //fetch investment pool poolId for indexbase functionality
        indexLayout.tokens = tokens;
    }

    /**
     * @inheritdoc Proxy
     * @notice fetch logic implementation address from external diamond proxy
     */
    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(INDEX_DIAMOND).facetAddress(msg.sig);
    }
}
