// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ShardVaultInternal } from './ShardVaultInternal.sol';
import { IShardVaultView } from './IShardVaultView.sol';

/**
 * @title ShardVaultView facet containing view functions
 */
contract ShardVaultView is ShardVaultInternal, IShardVaultView {
    constructor(address shardCollection) ShardVaultInternal(shardCollection) {}

    /**
     * @inheritdoc IShardVaultView
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function maxSupply() external view returns (uint256) {
        return _maxSupply();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function shardValue() external view returns (uint256) {
        return _shardValue();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function shardCollection() external view returns (address) {
        return _shardCollection();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function count() external view returns (uint256) {
        return _count();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function formatTokenId(uint96 internalId)
        external
        view
        returns (uint256 tokenId)
    {
        tokenId = _formatTokenId(internalId);
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function parseTokenId(uint256 tokenId)
        external
        pure
        returns (address vault, uint96 internalId)
    {
        (vault, internalId) = _parseTokenId(tokenId);
    }
}
