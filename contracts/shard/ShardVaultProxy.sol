// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol';
import { OwnableStorage } from '@solidstate/contracts/access/ownable/OwnableStorage.sol';
import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';

import { MarketPlaceHelperProxy } from '../helpers/MarketPlaceHelperProxy.sol';
import { IShardVault } from './IShardVault.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';

/**
 * @title Upgradeable proxy with externally controlled ShardVault implementation
 */
contract ShardVaultProxy is Proxy {
    address private immutable SHARD_VAULT_DIAMOND;

    /**
     * @notice emitted upon MarketPlaceHelperProxy deployment
     */
    event MarketPlaceHelperProxyDeployed(address marketPlacerHelperProxy);

    constructor(
        address shardVaultDiamond,
        address marketPlaceHelper,
        address collection,
        address jpegdVault,
        address jpegdVaultHelper,
        uint256 shardValue,
        uint16 maxSupply,
        uint16 maxMintBalance,
        bool isPUSDVault,
        IShardVault.FeeParams memory feeParams,
        IShardVault.BufferParams memory bufferParams,
        address[] memory authorized
    ) {
        SHARD_VAULT_DIAMOND = shardVaultDiamond;

        OwnableStorage.layout().owner = msg.sender;

        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        address marketPlaceHelperProxy = address(
            new MarketPlaceHelperProxy(marketPlaceHelper)
        );
        emit MarketPlaceHelperProxyDeployed(marketPlaceHelperProxy);

        l.marketPlaceHelper = marketPlaceHelperProxy;
        l.collection = collection;
        l.jpegdVault = jpegdVault;
        l.jpegdVaultHelper = jpegdVaultHelper;
        l.shardValue = shardValue;
        l.maxSupply = maxSupply;
        l.maxMintBalance = maxMintBalance;
        l.isPUSDVault = isPUSDVault;
        l.saleFeeBP = feeParams.saleFeeBP;
        l.acquisitionFeeBP = feeParams.acquisitionFeeBP;
        l.yieldFeeBP = feeParams.yieldFeeBP;
        l.ltvBufferBP = bufferParams.ltvBufferBP;
        l.ltvDeviationBP = bufferParams.ltvDeviationBP;
        l.conversionBuffer = bufferParams.conversionBuffer;

        uint256 authorizedLength = authorized.length;
        unchecked {
            for (uint256 i; i < authorizedLength; ++i) {
                l.authorized[authorized[i]] = true;
            }
        }
    }

    /**
     * @inheritdoc Proxy
     * @notice fetch logic implementation address from external diamond proxy
     */
    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(SHARD_VAULT_DIAMOND).facetAddress(msg.sig);
    }

    receive() external payable {}
}
