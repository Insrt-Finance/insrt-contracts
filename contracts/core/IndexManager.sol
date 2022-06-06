// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

import { IIndex } from '../index/IIndex.sol';
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
    address public immutable BALANCER_VAULT;

    constructor(
        address indexDiamond,
        address balancerInvestmentPoolFactory,
        address balancerVault
    ) {
        INDEX_DIAMOND = indexDiamond;
        INVESTMENT_POOL_FACTORY = balancerInvestmentPoolFactory;
        BALANCER_VAULT = balancerVault;
    }

    function deployIndex(
        IERC20[] calldata tokens,
        uint256[] calldata weights,
        uint256[] calldata amounts,
        uint16 exitFee
    ) external onlyOwner returns (address deployment) {
        deployment = address(
            new IndexProxy(
                INDEX_DIAMOND,
                INVESTMENT_POOL_FACTORY,
                BALANCER_VAULT,
                tokens,
                weights,
                ++IndexManagerStorage.layout().count,
                exitFee
            )
        );

        uint256 length = tokens.length;
        for (uint256 i; i < length; ) {
            tokens[i].transferFrom(msg.sender, deployment, amounts[i]);
            unchecked {
                ++i;
            }
        }

        IIndex(payable(deployment)).initialize(amounts);

        emit IndexDeployed(deployment);
    }
}
