// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';

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
    function purchaseAsset(
        EncodedCall[] calldata calls,
        address purchaseToken,
        uint256 price
    ) external payable {
        if (purchaseToken == address(0) && msg.value < price) {
            revert MarketPlaceHelper__InsufficientETH();
        } else if (
            purchaseToken != address(0) &&
            IERC20(purchaseToken).balanceOf(address(this)) < price
        ) {
            revert MarketPlaceHelper__InsufficientPurchaseToken();
        }

        for (uint256 i; i < calls.length; ) {
            unchecked {
                (bool success, ) = calls[i].target.call{
                    value: calls[i].value
                }(calls[i].data);
                if (!success) {
                    revert MarketPlaceHelper__FailedPurchaseCall();
                }
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IMarketPlaceHelper
     */
    function listAsset(EncodedCall[] memory calls) external {
        for (uint256 i; i < calls.length; ) {
            unchecked {
                (bool success, ) = calls[i].target.call{
                    value: calls[i].value
                }(calls[i].data);
                if (!success) {
                    revert MarketPlaceHelper__FailedListCall();
                }
                ++i;
            }
        }
    }

    //TODO
    function acceptAssetBid(
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
