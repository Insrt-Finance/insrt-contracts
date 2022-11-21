// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IShardVaultIO } from './IShardVaultIO.sol';
import { ShardVaultInternal } from './ShardVaultInternal.sol';

contract ShardVaultIO is IShardVaultIO, ShardVaultInternal {
    constructor(
        address shardCollection,
        address pUSD,
        address pETH,
        address punkMarket,
        address pusdCitadel,
        address pethCitadel,
        address lpFarm,
        address curvePUSDPool,
        address curvePETHPool,
        address booster,
        address marketplaceHelper,
        address jpeg
    )
        ShardVaultInternal(
            shardCollection,
            pUSD,
            pETH,
            punkMarket,
            pusdCitadel,
            pethCitadel,
            lpFarm,
            curvePUSDPool,
            curvePETHPool,
            booster,
            marketplaceHelper,
            jpeg
        )
    {}

    /**
     * @inheritdoc IShardVaultIO
     */
    function deposit() external payable {
        _deposit();
    }

    /**
     * @inheritdoc IShardVaultIO
     */
    function withdraw(uint256[] memory tokenIds) external payable {
        _withdraw(tokenIds);
    }

    /**
     * @inheritdoc IShardVaultIO
     */
    function beforeShardTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external {
        _beforeShardTransfer(from, to, tokenId);
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
