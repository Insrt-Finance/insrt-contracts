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

    address internal immutable SHARDS;

    constructor(address shardCollection) {
        SHARDS = shardCollection;
    }

    function _onlyProtocolOwner(address account) internal view {
        if (account != _protocolOwner()) {
            revert Errors.OnlyProtocolOwner();
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
        uint256 mintedShards = l.mintedShards;

        if (amount % shardValue != 0 || amount == 0) {
            revert Errors.InvalidDepositAmount();
        }
        if (l.invested || l.vaultFull) {
            revert Errors.DepositForbidden();
        }

        uint256 shards = amount / l.shardValue;
        uint256 excessShards;

        if (shards + mintedShards >= l.maxShards) {
            l.vaultFull = true;
            excessShards = shards + mintedShards - l.maxShards;
        }

        shards -= excessShards;
        l.mintedShards += shards;

        for (uint256 i; i < shards; ) {
            unchecked {
                IShardCollection(SHARDS).mint(
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
            revert Errors.WithdrawalForbidden();
        }

        uint256 tokens = tokenIds.length;

        for (uint256 i; i < tokens; ) {
            if (ISolidStateERC721(SHARDS).ownerOf(tokenIds[i]) != msg.sender) {
                revert Errors.OnlyShardOwner();
            }

            IShardCollection(SHARDS).burn(tokenIds[i]);
        }

        l.mintedShards -= tokens;

        payable(msg.sender).sendValue(tokens * l.shardValue);
    }

    /**
     * @notice returns total minted shards amount
     */
    function _mintedShards() internal view returns (uint256) {
        return ShardVaultStorage.layout().mintedShards;
    }

    /**
     * @notice returns ETH value of shard
     */
    function _shardValue() internal view returns (uint256) {
        return ShardVaultStorage.layout().shardValue;
    }

    function _generateTokenId(uint256 count)
        private
        view
        returns (uint256 tokenId)
    {
        assembly {
            tokenId := or(shl(96, address()), count)
        }
    }
}
