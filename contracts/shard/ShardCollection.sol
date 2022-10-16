// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { SolidStateERC721 } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';
import { IERC173 } from '@solidstate/contracts/access/IERC173.sol';
import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';

import { Errors } from './Errors.sol';
import { IShardCollection } from './IShardCollection.sol';
import { ShardCollectionStorage } from './ShardCollectionStorage.sol';

contract ShardCollection is
    SolidStateERC721,
    OwnableInternal,
    IShardCollection
{
    /**
     * @notice returns the protocol owner
     * @return address of the protocol owner
     */
    function _protocolOwner() internal view returns (address) {
        return IERC173(_owner()).owner();
    }

    function mint(address to, uint256 tokenId) external {
        _onlyVault(msg.sender);
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _onlyVault(msg.sender);
        _burn(tokenId);
    }

    function addToWhitelist(address vault) external {
        _onlyProtocolOwner(msg.sender);
        ShardCollectionStorage.layout().vaults[vault] = true;
    }

    function removeFromWhitelist(address vault) external {
        _onlyProtocolOwner(msg.sender);
        ShardCollectionStorage.layout().vaults[vault] = false;
    }

    function _onlyVault(address account) internal view {
        if (!ShardCollectionStorage.layout().vaults[account]) {
            revert Errors.ShardCollection__OnlyVault();
        }
    }

    function _onlyProtocolOwner(address account) internal view {
        if (account != _protocolOwner()) {
            revert Errors.ShardCollection__OnlyProtocolOwner();
        }
    }
}
