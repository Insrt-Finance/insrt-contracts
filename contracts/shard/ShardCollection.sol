// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ERC721BaseInternal } from '@solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol';
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
    SolidStateERC721,
    Ownable,
    IShardCollection
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

    /**
     * @inheritdoc ShardCollectionInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ShardCollectionInternal, SolidStateERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal override(ERC721BaseInternal, SolidStateERC721) {
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @inheritdoc ERC721BaseInternal
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal override(ERC721BaseInternal, SolidStateERC721) {
        super._handleTransferMessageValue(from, to, tokenId, value);
    }
}
