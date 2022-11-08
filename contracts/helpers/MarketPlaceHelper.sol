// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { IERC721 } from '@solidstate/contracts/token/ERC721/IERC721.sol';

import { IMarketPlaceHelper } from './IMarketPlaceHelper.sol';
import { ICryptoPunkMarket } from '../interfaces/cryptopunk/ICryptoPunkMarket.sol';

contract MarketPlaceHelper is IMarketPlaceHelper {
    using AddressUtils for address payable;

    address private immutable CRYPTO_PUNK_MARKET;

    constructor(address cryptoPunkMarket) {
        CRYPTO_PUNK_MARKET = cryptoPunkMarket;
    }

    /**
     * @inheritdoc IMarketPlaceHelper
     */
    function purchaseERC721Asset(
        bytes calldata data,
        address target,
        address collection,
        address purchaseToken,
        uint256 tokenId,
        uint256 price
    ) external payable {
        if (purchaseToken == address(0) && msg.value != price) {
            revert MarketPlaceHelper__InsufficientETH();
        } else if (
            purchaseToken != address(0) &&
            IERC20(purchaseToken).balanceOf(address(this)) < price
        ) {
            revert MarketPlaceHelper__InsufficientPurchaseToken();
        }

        (bool success, ) = target.call{ value: msg.value }(data);

        if (!success) {
            revert MarketPlaceHelper__FailedPurchaseCall();
        }

        if (collection == CRYPTO_PUNK_MARKET) {
            //check of ownership done in `transferPunk`
            ICryptoPunkMarket(CRYPTO_PUNK_MARKET).transferPunk(
                msg.sender,
                tokenId
            );
        } else {
            //check of ownership done in `transferFrom`
            IERC721(collection).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );
        }
    }

    /**
     * @inheritdoc IMarketPlaceHelper
     */
    function listERC721Asset(bytes calldata data, address target) external {
        (bool success, ) = target.call(data);

        if (!success) {
            revert MarketPlaceHelper__FailedListCall();
        }
    }

    //TODO
    function acceptERC721Bid(
        bytes calldata data,
        address target,
        address collection,
        uint256 tokenId,
        uint256 minBidValue
    ) external payable {
        if (collection == CRYPTO_PUNK_MARKET) {
            ICryptoPunkMarket(CRYPTO_PUNK_MARKET).acceptBidForPunk(
                tokenId,
                minBidValue
            );

            uint256 oldBalance = address(this).balance;
            ICryptoPunkMarket(CRYPTO_PUNK_MARKET).withdraw();
            uint256 newBalance = address(this).balance;

            unchecked {
                payable(msg.sender).sendValue(newBalance - oldBalance);
            }
        } else {
            (bool success, ) = target.call(data);

            if (!success) {
                revert MarketPlaceHelper__FailedBidAcceptanceCall();
            }
        }
    }
}
