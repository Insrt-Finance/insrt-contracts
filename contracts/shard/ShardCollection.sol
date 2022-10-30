// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { SolidStateERC721 } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';
import { IERC173 } from '@solidstate/contracts/access/IERC173.sol';
import { SafeOwnable } from '@solidstate/contracts/access/ownable/SafeOwnable.sol';

import { IShardCollection } from './IShardCollection.sol';
import { ShardCollectionStorage } from './ShardCollectionStorage.sol';

contract ShardCollection is SolidStateERC721, SafeOwnable, IShardCollection {
    modifier onlyVault() {
        _onlyVault(msg.sender);
        _;
    }

    function mint(address to, uint256 tokenId) external onlyVault {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyVault {
        _burn(tokenId);
    }

    function addToWhitelist(address vault) external onlyOwner {
        ShardCollectionStorage.layout().vaults[vault] = true;
    }

    function removeFromWhitelist(address vault) external onlyOwner {
        ShardCollectionStorage.layout().vaults[vault] = false;
    }

    function _onlyVault(address account) internal view {
        if (!ShardCollectionStorage.layout().vaults[account]) {
            revert ShardCollection__OnlyVault();
        }
    }
}
