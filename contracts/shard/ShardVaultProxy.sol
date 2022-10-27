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
        uint256 shardValue,
        uint256 maxSupply,
        uint256 id,
        uint256 salesFeeBP,
        uint256 fundraiseFeeBP,
        uint256 yieldFeeBP,
        uint256 bufferBP,
        uint256 deviationBP
    ) {
        SHARD_VAULT_DIAMOND = shardVaultDiamond;

        OwnableStorage.layout().owner = msg.sender;

        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        l.id = id;
        l.collection = collection;
        l.jpegdVault = jpegdVault;
        l.shardValue = shardValue;
        l.maxSupply = maxSupply;
        l.salesFeeBP = salesFeeBP;
        l.fundraiseFeeBP = fundraiseFeeBP;
        l.yieldFeeBP = yieldFeeBP;
        l.bufferBP = bufferBP;
        l.deviationBP = deviationBP;
    }

    /**
     * @inheritdoc Proxy
     * @notice fetch logic implementation address from external diamond proxy
     */
    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(SHARD_VAULT_DIAMOND).facetAddress(msg.sig);
    }
}
