// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { SolidStateERC721 } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';
import { Ownable } from '@solidstate/contracts/access/ownable/Ownable.sol';

import { IShardCollection } from './IShardCollection.sol';
import { ShardCollectionInternal } from './ShardCollectionInternal.sol';
import { ShardCollectionStorage } from './ShardCollectionStorage.sol';

/**
 * @title ShardCollection for ShardVault tokens
 */
contract ShardCollection is
    ShardCollectionInternal,
    IShardCollection,
    SolidStateERC721,
    Ownable
{
    /**
     * @inheritdoc IShardCollection
     */
    function mint(address to, uint256 tokenId) external onlyVault {
        _mint(to, tokenId);
    }

    /**
     * @inheritdoc IShardCollection
     */
    function burn(uint256 tokenId) external onlyVault {
        _burn(tokenId);
    }

    /**
     * @inheritdoc IShardCollection
     */
    function addToWhitelist(address vault) external onlyOwner {
        _addToWhitelist(vault);
    }

    /**
     * @inheritdoc IShardCollection
     */
    function removeFromWhitelist(address vault) external onlyOwner {
        _removeFromWhitelist(vault);
    }

    /**
     * @inheritdoc IShardCollection
     */
    function isWhitelisted(address vault) external view returns (bool) {
        return _isWhitelisted(vault);
    }
}
