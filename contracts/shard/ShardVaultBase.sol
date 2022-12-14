// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC721Receiver } from '@solidstate/contracts/interfaces/IERC721Receiver.sol';

import { ShardVaultInternal } from './ShardVaultInternal.sol';

contract ShardVaultBase is ShardVaultInternal, IERC721Receiver {
    constructor(
        JPEGParams memory jpegParams,
        AuxiliaryParams memory auxiliaryParams
    ) ShardVaultInternal(jpegParams, auxiliaryParams) {}

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
