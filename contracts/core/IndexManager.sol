// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { OwnableInternal } from '@solidstate/contracts/access/OwnableInternal.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

import { IndexProxy } from '../index/IndexProxy.sol';
import { IIndexManager } from './IIndexManager.sol';
import { IndexManagerStorage } from './IndexManagerStorage.sol';

/**
 * @title Index management contract
 * @dev deployed standalone and connected to core as diamond facet
 */
contract IndexManager is IIndexManager, OwnableInternal {
    address public immutable INDEX_DIAMOND;
    address public immutable INVESTMENT_POOL_FACTORY;

    constructor(address indexDiamond, address balancerInvestmentPoolFactory) {
        INDEX_DIAMOND = indexDiamond;

        INVESTMENT_POOL_FACTORY = balancerInvestmentPoolFactory;
    }

    function deployIndex(
        IERC20[] calldata tokens,
        uint256[] calldata weights,
        uint16 exitFee
    ) external onlyOwner returns (address deployment) {
        deployment = address(
            new IndexProxy(
                INDEX_DIAMOND,
                INVESTMENT_POOL_FACTORY,
                tokens,
                weights,
                ++IndexManagerStorage.layout().count,
                exitFee
            )
        );

        emit IndexDeployed(deployment);
    }
}
