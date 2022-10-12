// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ShardVaultInternal } from './ShardVaultInternal.sol';
import { IShardVaultView } from './IShardVaultView.sol';

/**
 * @title ShardVaultView facet containing view functions
 */
contract ShardVaultView is ShardVaultInternal, IShardVaultView {
    /**
     * @inheritdoc IShardVaultView
     */
    function depositorShards(address account) external view returns (uint256) {
        return _depositorShards(account);
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function owedShards() external view returns (uint256) {
        return _owedShards();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function shardSize() external view returns (uint256) {
        return _shardSize();
    }
}
