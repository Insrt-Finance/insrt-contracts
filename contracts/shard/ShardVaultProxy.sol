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

    struct FeeParams {
        uint256 saleFeeBP;
        uint256 acquisitionFeeBP;
        uint256 yieldFeeBP;
    }

    struct BufferParams {
        uint256 ltvBufferBP;
        uint256 ltvDeviationBP;
        uint256 conversionBuffer;
    }

    constructor(
        address shardVaultDiamond,
        address collection,
        address jpegdVault,
        address jpegdVaultHelper,
        uint256 shardValue,
        uint256 maxSupply,
        uint256 id,
        FeeParams memory feeParams,
        BufferParams memory bufferParams
    ) {
        SHARD_VAULT_DIAMOND = shardVaultDiamond;

        OwnableStorage.layout().owner = msg.sender;

        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        l.id = id;
        l.collection = collection;
        l.jpegdVault = jpegdVault;
        l.jpegdVaultHelper = jpegdVaultHelper;
        l.shardValue = shardValue;
        l.maxSupply = maxSupply;
        l.saleFeeBP = feeParams.saleFeeBP;
        l.acquisitionFeeBP = feeParams.acquisitionFeeBP;
        l.yieldFeeBP = feeParams.yieldFeeBP;
        l.ltvBufferBP = bufferParams.ltvBufferBP;
        l.ltvDeviationBP = bufferParams.ltvDeviationBP;
        l.conversionBuffer = bufferParams.conversionBuffer;
    }

    /**
     * @inheritdoc Proxy
     * @notice fetch logic implementation address from external diamond proxy
     */
    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(SHARD_VAULT_DIAMOND).facetAddress(msg.sig);
    }
}
