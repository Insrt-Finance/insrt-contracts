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

    /**
     * @notice thrown when insufficient ETH is transferred
     */
    error MarketPlaceHelper__InsufficientETH();

    /**
     * @notice thrown when insufficient purchaseToken is transferred
     */
    error MarketPlaceHelper__InsufficientPurchaseToken();

    /**
     * @notice thrown when bid acceptance call fails
     */
    error MarketPlaceHelper__FailedBidAcceptanceCall();

    /**
     * @notice thrown when datas and targets arrays have different lengths
     */
    error MarketPlaceHelper__UnequalCallArraysLength();

    /**
     * @notice ERC721 purchasing call made to arbitrary marketplace
     * @param datas array of calldatas required for purchasing call
     * @param targets arrays of addresses of target contract addresses for purchasing calls
     * @param values msg.value of each arbitrary call made to `targets` with `datas`
     * @param collection address of NFT collection
     * @param purchaseToken address of token used to transact - if address(0) ETH is used
     * @param tokenId id of token in NFT collection
     * @param price purchase price
     */
    function purchaseERC721Asset(
        bytes[] calldata datas,
        address[] calldata targets,
        uint256[] calldata values,
        address collection,
        address purchaseToken,
        uint256 tokenId,
        uint256 price
    ) external payable;

    /**
     * @notice ERC721 listing call made to arbitrary marketplace
     * @param data calldata required for listing call
     * @param target address of target marketplace
     */
    function listERC721Asset(bytes calldata data, address target) external;
}
