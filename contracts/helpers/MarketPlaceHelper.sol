// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';
import { Ownable } from '@solidstate/contracts/access/ownable/Ownable.sol';

import { IMarketPlaceHelper } from './IMarketPlaceHelper.sol';
import { ICryptoPunkMarket } from '../interfaces/cryptopunk/ICryptoPunkMarket.sol';

contract MarketPlaceHelper is IMarketPlaceHelper, Ownable {
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
    ) external payable onlyOwner {
        if (purchaseToken == address(0) && msg.value < price) {
            revert MarketPlaceHelper__InsufficientETH();
        } else if (
            purchaseToken != address(0) &&
            IERC20(purchaseToken).balanceOf(address(this)) < price
        ) {
            revert MarketPlaceHelper__InsufficientPurchaseToken();
        }

        unchecked {
            for (uint256 i; i < calls.length; ++i) {
                (bool success, ) = calls[i].target.call{
                    value: calls[i].value
                }(calls[i].data);
                if (!success) {
                    revert MarketPlaceHelper__FailedPurchaseCall();
                }
            }
        }
    }

    /**
     * @inheritdoc IMarketPlaceHelper
     */
    function listAsset(EncodedCall[] memory calls) external onlyOwner {
        unchecked {
            for (uint256 i; i < calls.length; ++i) {
                (bool success, ) = calls[i].target.call{
                    value: calls[i].value
                }(calls[i].data);
                if (!success) {
                    revert MarketPlaceHelper__FailedListCall();
                }
            }
        }
    }

    /**
     * @inheritdoc IMarketPlaceHelper
     */
    function acceptAssetBid(EncodedCall[] memory calls) external onlyOwner {
        for (uint256 i; i < calls.length; ) {
            unchecked {
                (bool success, ) = calls[i].target.call{
                    value: calls[i].value
                }(calls[i].data);
                if (!success) {
                    revert MarketPlaceHelper__FailedAcceptBidCall();
                }
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IMarketPlaceHelper
     */
    function forwardSaleProceeds(
        EncodedCall[] memory calls
    ) external payable onlyOwner returns (uint256 proceeds) {
        for (uint256 i; i < calls.length; ) {
            unchecked {
                (bool success, ) = calls[i].target.call{
                    value: calls[i].value
                }(calls[i].data);
                if (!success) {
                    revert MarketPlaceHelper__FailedForwardSaleProceedsCall();
                }
                ++i;
            }
        }

        proceeds = address(this).balance;
        if (proceeds != 0) {
            payable(msg.sender).sendValue(proceeds);
        }
    }
}
