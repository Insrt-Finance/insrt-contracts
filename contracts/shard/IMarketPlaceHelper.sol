// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IMarketPlaceHelper {
    /**
     * @notice thrown when purchase call to target market is unsuccessfull
     */
    error MarketPlaceHelper__FailedPurchaseCall();

    /**
     * @notice thrown when list call to target market is unsuccessfull
     */
    error MarketPlaceHelper__FailedListCall();

    error MarketPlaceHelper__InsufficientETH();

    error MarketPlaceHelper__InsufficientPurchaseToken();

    error MarketPlaceHelper__PunkNotListed();

    error MarketPlaceHelper__InsufficientPunkPrice();

    /**
     * @notice NFT purchasing call to arbitrary market
     * @param data calldata required for purchasing call
     * @param target address of target market
     * @param collection address of NFT collection
     * @param purchaseToken address of token used to transact - if address(0) ETH is used
     * @param tokenId id of token in NFT collection
     * @param price purchase price
     */
    function purchaseERC721Asset(
        bytes calldata data,
        address target,
        address collection,
        address purchaseToken,
        uint256 tokenId,
        uint256 price
    ) external payable;
}
