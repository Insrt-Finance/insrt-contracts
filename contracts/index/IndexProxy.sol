// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { OwnableStorage } from '@solidstate/contracts/access/ownable/OwnableStorage.sol';
import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';
import { IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { ERC4626BaseStorage } from '@solidstate/contracts/token/ERC4626/base/ERC4626BaseStorage.sol';
import { UintUtils } from '@solidstate/contracts/utils/UintUtils.sol';

import { IInvestmentPoolFactory } from '../interfaces/balancer/IInvestmentPoolFactory.sol';
import { IInvestmentPool } from '../interfaces/balancer/IInvestmentPool.sol';
import { IndexStorage } from './IndexStorage.sol';

/**
 * @title Upgradeable proxy with externally controlled Index implementation
 */
contract IndexProxy is Proxy {
    using UintUtils for uint256;

    address private immutable INDEX_DIAMOND;

    constructor(
        address indexDiamond,
        address investmentPoolFactory,
        address balancerVault,
        IERC20[] memory tokens,
        uint256[] memory weights,
        uint256 id
    ) {
        INDEX_DIAMOND = indexDiamond;

        OwnableStorage.layout().owner = msg.sender;

        string memory metadata = string(
            abi.encodePacked('IFII-BPT-', id.toString())
        );

        // deploy Balancer pool

        address balancerPool = IInvestmentPoolFactory(investmentPoolFactory)
            .create(
                metadata,
                metadata,
                tokens,
                weights,
                0.015 ether, // swapFeePercentage: 1.5%
                address(this),
                // TODO: implications of swapEnabledOnStart?
                true,
                0
            );

        // set balancer pool as base ERC4626 asset
        ERC4626BaseStorage.layout().asset = balancerPool;

        IndexStorage.Layout storage l = IndexStorage.layout();

        l.id = id;
        l.poolId = IInvestmentPool(balancerPool).getPoolId();
        l.tokens = tokens;

        uint256 indexTokensLength = tokens.length;
        for (uint256 i; i < indexTokensLength; ) {
            tokens[i].approve(balancerVault, type(uint256).max);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc Proxy
     * @notice fetch logic implementation address from external diamond proxy
     */
    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(INDEX_DIAMOND).facetAddress(msg.sig);
    }
}
