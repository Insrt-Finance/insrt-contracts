// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { SafeOwnable } from '@solidstate/contracts/access/SafeOwnable.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

import { IndexProxy } from './IndexProxy.sol';
import { IndexDiamond } from './IndexDiamond.sol';

/**
 * @title Index management contract
 */
contract IndexManager is SafeOwnable {
    address public immutable INDEX_DIAMOND;
    address public immutable INVESTMENT_POOL_FACTORY;

    event IndexDeployed(address deployment);

    constructor(address balancerInvestmentPoolFactory) {
        // TODO: set owner
        IndexDiamond indexDiamond = new IndexDiamond();
        // TODO: set diamond owner
        INDEX_DIAMOND = address(indexDiamond);

        INVESTMENT_POOL_FACTORY = balancerInvestmentPoolFactory;
    }

    function deployIndex(IERC20[] calldata tokens, uint256[] calldata weights)
        external
        onlyOwner
        returns (address deployment)
    {
        deployment = address(
            new IndexProxy(
                INDEX_DIAMOND,
                INVESTMENT_POOL_FACTORY,
                tokens,
                weights
            )
        );

        emit IndexDeployed(deployment);
    }
}
