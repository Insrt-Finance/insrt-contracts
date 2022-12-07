// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IShardVaultIO } from './IShardVaultIO.sol';
import { ShardVaultInternal } from './ShardVaultInternal.sol';

contract ShardVaultIO is IShardVaultIO, ShardVaultInternal {
    constructor(
        JPEGParams memory jpegParams,
        AuxiliaryParams memory auxiliaryParams
    ) ShardVaultInternal(jpegParams, auxiliaryParams) {}

    /**
     * @inheritdoc IShardVaultIO
     */
    function deposit() external payable {
        _deposit();
    }

    /**
     * @inheritdoc IShardVaultIO
     */
    function withdraw(uint256[] memory shardIds) external payable {
        _withdraw(shardIds);
    }

    /**
     * @inheritdoc IShardVaultIO
     */
    function implicitClaim(address from, address to, uint256 tokenId) external {
        _implicitClaim(from, to, tokenId);
    }

    /**
     * @inheritdoc IShardVaultIO
     */
    function claimYield(uint256[] memory tokenIds) external {
        _claimYield(msg.sender, tokenIds);
    }

    /**
     * @inheritdoc IShardVaultIO
     */
    function claimExcessETH(uint256[] memory tokenIds) external {
        _claimExcessETH(msg.sender, tokenIds);
    }
}
