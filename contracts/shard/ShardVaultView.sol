// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ShardVaultInternal } from './ShardVaultInternal.sol';
import { IShardVaultView } from './IShardVaultView.sol';

/**
 * @title ShardVaultView facet containing view functions
 */
contract ShardVaultView is ShardVaultInternal, IShardVaultView {
    constructor(address shardsCollection)
        ShardVaultInternal(shardsCollection)
    {}

    /**
     * @inheritdoc IShardVaultView
     */
    function mintedShards() external view returns (uint256) {
        return _mintedShards();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function shardValue() external view returns (uint256) {
        return _shardValue();
    }
}
