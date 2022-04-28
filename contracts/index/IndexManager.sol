// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { SafeOwnable } from '@solidstate/contracts/access/SafeOwnable.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

import { IInvestmentPoolFactory } from '../balancer/IInvestmentPoolFactory.sol';
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

    function deployIndex(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256[] memory weights,
        uint256 swapFeePercentage
    ) external onlyOwner returns (address deployment) {
        // TODO: metadata naming conventions?

        // TODO: difference between owner and assetManagers?
        address owner = owner();
        address[] memory assetManagers = new address[](1);
        assetManagers[0] = owner;

        // TODO: implications?
        bool swapEnabledOnStart = true;

        address investmentPool = IInvestmentPoolFactory(INVESTMENT_POOL_FACTORY)
            .create(
                name,
                symbol,
                tokens,
                weights,
                assetManagers,
                swapFeePercentage,
                owner,
                swapEnabledOnStart
            );

        deployment = address(new IndexProxy(INDEX_DIAMOND, investmentPool));

        emit IndexDeployed(deployment);
    }
}
