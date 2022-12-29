// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC721Receiver } from '@solidstate/contracts/interfaces/IERC721Receiver.sol';
import { ERC721BaseInternal } from '@solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol';
import { SolidStateERC721 } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';

import { ShardVaultInternal } from './ShardVaultInternal.sol';

contract ShardVaultBase is
    ShardVaultInternal,
    SolidStateERC721,
    IERC721Receiver
{
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

    /**
     * @inheritdoc SolidStateERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ShardVaultInternal, SolidStateERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @inheritdoc SolidStateERC721
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(SolidStateERC721, ERC721BaseInternal) {
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @inheritdoc SolidStateERC721
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(SolidStateERC721, ERC721BaseInternal) {
        super._handleTransferMessageValue(from, to, tokenId, value);
    }
}
