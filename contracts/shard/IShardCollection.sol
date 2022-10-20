// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ISolidStateERC721 } from '@solidstate/contracts/token/ERC721/ISolidStateERC721.sol';

interface IShardCollection is ISolidStateERC721 {
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
     * @notice whitelists an address for minting/burning tokens
     * @param vault address of vault
     */
    function addToWhitelist(address vault) external;

    /**
     * @notice removes a vault from whitelist
     * @param vault address of vault
     */
    function removeFromWhitelist(address vault) external;
}
