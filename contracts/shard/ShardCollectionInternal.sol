// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ERC721MetadataStorage } from '@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol';
import { ERC721BaseInternal } from '@solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol';
import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';

import { IShardCollectionInternal } from './IShardCollectionInternal.sol';
import { IShardVault } from './IShardVault.sol';
import { ShardCollectionStorage } from './ShardCollectionStorage.sol';
import { ShardId } from './ShardId.sol';

/**
 * @title Internal logic for ShardCollection
 */
contract ShardCollectionInternal is
    ERC721BaseInternal,
    IShardCollectionInternal
{
    modifier onlyVault() {
        _onlyVault(msg.sender);
        _;
    }

    /**
     * @notice enforces whitelist
     * @param account address to check
     */
    function _onlyVault(address account) internal view {
        if (!ShardCollectionStorage.layout().whitelist[account]) {
            revert ShardCollection__OnlyVault();
        }
    }

    /**
     * @notice whitelists an address
     * @param vault address to add
     */
    function _addToWhitelist(address vault) internal {
        ShardCollectionStorage.layout().whitelist[vault] = true;
        emit WhitelistAddition(vault);
    }

    /**
     * @notice removes an address from whitelist
     * @param vault address to remove
     */
    function _removeFromWhitelist(address vault) internal {
        ShardCollectionStorage.layout().whitelist[vault] = false;
        emit WhitelistRemoval(vault);
    }

    /**
     * @notice returns whitelisted state of an address
     * @param vault vault address
     * @return bool whitelisted state
     */
    function _isWhitelisted(address vault) internal view returns (bool) {
        return ShardCollectionStorage.layout().whitelist[vault];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        (address shardVault, ) = ShardId.parseTokenId(tokenId);
        IShardVault(shardVault).implicitClaim(from, to, tokenId);
    }

    /**
     * @notice sets base URI for shard collection
     * @param baseURI base URI string
     */
    function _setBaseURI(string memory baseURI) internal {
        ERC721MetadataStorage.layout().baseURI = baseURI;
    }

    /**
     * @notice sets name for shard collection
     * @param name name string
     */
    function _setName(string memory name) internal {
        ERC721MetadataStorage.layout().name = name;
    }

    /**
     * @notice sets symbol for shard collection
     * @param symbol symbol string
     */
    function _setSymbol(string memory symbol) internal {
        ERC721MetadataStorage.layout().symbol = symbol;
    }
}
