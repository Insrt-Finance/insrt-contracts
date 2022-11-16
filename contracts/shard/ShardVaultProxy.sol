// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol';
import { OwnableStorage } from '@solidstate/contracts/access/ownable/OwnableStorage.sol';
import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';

import { ShardVaultStorage } from './ShardVaultStorage.sol';

/**
 * @title Upgradeable proxy with externally controlled ShardVault implementation
 */
contract ShardVaultProxy is Proxy {
    address private immutable SHARD_VAULT_DIAMOND;

    constructor(
        address shardVaultDiamond,
        address collection,
        address jpegdVault,
        address jpegdVaultHelper,
        uint256 shardValue,
        uint16 maxSupply,
        uint16 saleFeeBP,
        uint16 acquisitionFeeBP,
        uint16 yieldFeeBP,
        uint16 bufferBP,
        uint16 deviationBP,
        uint16 maxShardsPerUser
    ) {
        SHARD_VAULT_DIAMOND = shardVaultDiamond;

        OwnableStorage.layout().owner = msg.sender;

        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        l.collection = collection;
        l.jpegdVault = jpegdVault;
        l.jpegdVaultHelper = jpegdVaultHelper;
        l.shardValue = shardValue;
        l.maxSupply = maxSupply;
        l.saleFeeBP = saleFeeBP;
        l.acquisitionFeeBP = acquisitionFeeBP;
        l.yieldFeeBP = yieldFeeBP;
        l.bufferBP = bufferBP;
        l.deviationBP = deviationBP;
        l.maxShardsPerUser = maxShardsPerUser;
    }

    /**
     * @inheritdoc Proxy
     * @notice fetch logic implementation address from external diamond proxy
     */
    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(SHARD_VAULT_DIAMOND).facetAddress(msg.sig);
    }
}
