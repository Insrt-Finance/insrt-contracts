// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC721Receiver } from '@solidstate/contracts/interfaces/IERC721Receiver.sol';

import { ShardVaultInternal } from './ShardVaultInternal.sol';

contract ShardVaultBase is ShardVaultInternal, IERC721Receiver {
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
        address jpegCardCigStaking
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
            jpegCardCigStaking
        )
    {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256('onERC721Received(address,address,uint256,bytes)')
            );
    }
}
