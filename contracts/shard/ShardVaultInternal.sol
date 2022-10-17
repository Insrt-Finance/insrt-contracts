// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';
import { IERC173 } from '@solidstate/contracts/access/IERC173.sol';
import { ISolidStateERC721 } from '@solidstate/contracts/token/ERC721/ISolidStateERC721.sol';
import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';

import { Errors } from './Errors.sol';
import { IShardCollection } from './IShardCollection.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';

/**
 * @title Shard Vault internal functions
 * @dev inherited by all Shard Vault implementation contracts
 */
abstract contract ShardVaultInternal is OwnableInternal {
    using AddressUtils for address payable;

    address internal immutable SHARD_COLLECTION;

    constructor(address shardCollection) {
        SHARD_COLLECTION = shardCollection;
    }

    modifier onlyProtocolOwner() {
        _onlyProtocolOwner(msg.sender);
        _;
    }

    function _onlyProtocolOwner(address account) internal view {
        if (account != _protocolOwner()) {
            revert Errors.ShardVault__OnlyProtocolOwner();
        }
    }

    /**
     * @notice returns the protocol owner
     * @return address of the protocol owner
     */
    function _protocolOwner() internal view returns (address) {
        return IERC173(_owner()).owner();
    }

    /**
     * @notice deposits ETH in exchange for owed shards
     */
    function _deposit() internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        uint256 amount = msg.value;
        uint256 shardValue = l.shardValue;
        uint256 totalSupply = l.totalSupply;

        if (amount % shardValue != 0 || amount == 0) {
            revert Errors.ShardVault__InvalidDepositAmount();
        }
        if (l.invested || l.vaultFull) {
            revert Errors.ShardVault__DepositForbidden();
        }

        uint256 shards = amount / l.shardValue;
        uint256 excessShards;

        if (shards + totalSupply >= l.maxSupply) {
            l.vaultFull = true;
            excessShards = shards + totalSupply - l.maxSupply;
        }

        shards -= excessShards;
        l.totalSupply += shards;

        for (uint256 i; i < shards; ) {
            unchecked {
                IShardCollection(SHARD_COLLECTION).mint(
                    msg.sender,
                    _generateTokenId(++l.count)
                );
                ++i;
            }
        }

        if (excessShards > 0) {
            payable(msg.sender).sendValue(excessShards * shardValue);
        }
    }

    /**
     * @notice withdraws ETH for an amount of shards
     * @param tokenIds the tokenIds of shards to burn
     */
    function _withdraw(uint256[] memory tokenIds) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        if (l.invested || l.vaultFull) {
            revert Errors.ShardVault__WithdrawalForbidden();
        }

        uint256 tokens = tokenIds.length;

        if (
            ISolidStateERC721(SHARD_COLLECTION).balanceOf(msg.sender) < tokens
        ) {
            revert Errors.ShardVault__InsufficientShards();
        }

        for (uint256 i; i < tokens; ) {
            unchecked {
                if (
                    ISolidStateERC721(SHARD_COLLECTION).ownerOf(tokenIds[i]) !=
                    msg.sender
                ) {
                    revert Errors.ShardVault__OnlyShardOwner();
                }
                if (_addressFromTokenId(tokenIds[i]) != address(this)) {
                    revert Errors.ShardVault__VaultTokenIdMismatch();
                }

                IShardCollection(SHARD_COLLECTION).burn(tokenIds[i]);
                ++i;
            }
        }

        l.totalSupply -= tokens;

        payable(msg.sender).sendValue(tokens * l.shardValue);
    }

    /**
     * @notice returns total minted shards amount
     */
    function _totalSupply() internal view returns (uint256) {
        return ShardVaultStorage.layout().totalSupply;
    }

    /**
     * @notice returns maximum possible minted shards
     */
    function _maxSupply() internal view returns (uint256) {
        return ShardVaultStorage.layout().maxSupply;
    }

    /**
     * @notice returns ETH value of shard
     */
    function _shardValue() internal view returns (uint256) {
        return ShardVaultStorage.layout().shardValue;
    }

    /**
     * @notice return ShardCollection address
     */
    function _shardCollection() internal view returns (address) {
        return SHARD_COLLECTION;
    }

    /**
     * @notice return minted token count
     * @dev does not reduce when tokens are burnt
     */
    function _count() internal view returns (uint256) {
        return ShardVaultStorage.layout().count;
    }

    function _generateTokenId(uint256 count)
        private
        view
        returns (uint256 tokenId)
    {
        tokenId = ((uint256(uint160(address(this))) << 96) | count);
    }

    function _addressFromTokenId(uint256 tokenId)
        private
        pure
        returns (address)
    {
        return address(uint160(tokenId >> 96));
    }
}
