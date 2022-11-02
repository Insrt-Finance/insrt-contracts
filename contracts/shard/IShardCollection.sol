// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ISolidStateERC721 } from '@solidstate/contracts/token/ERC721/ISolidStateERC721.sol';

import { IShardCollectionInternal } from './IShardCollectionInternal.sol';

interface IShardCollection is ISolidStateERC721, IShardCollectionInternal {
    /**
     * @notice mints a token
     * @param to address to mint to
     * @param tokenId tokenId of the token to mint
     */
    function mint(address to, uint256 tokenId) external;

    /**
     * @notice burns a token
     * @param tokenId the id of the token to burn
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice whitelists an address
     * @param vault address to add
     */
    function addToWhitelist(address vault) external;

    /**
     * @notice removes an address from whitelist
     * @param vault address to remove
     */
    function removeFromWhitelist(address vault) external;

    /**
     * @notice returns whitelisted state of an address
     * @param vault vault address
     * @return bool whitelisted state
     */
    function isWhitelisted(address vault) external view returns (bool);
}
