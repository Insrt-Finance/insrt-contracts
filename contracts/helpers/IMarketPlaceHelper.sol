// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IMarketPlaceHelper {
    struct EncodedCall {
        bytes data; //encoded call data
        uint256 value; //call msg.value
        address target; //call target address
    }

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
    error MarketPlaceHelper__FailedAcceptBidCall();

    /**
     * @notice thrown when withdrawing + forwarding sale proceeds fails
     */
    error MarketPlaceHelper__FailedForwardSaleProceedsCall();

    /**
     * @notice purchasing call made to arbitrary marketplace
     * @param calls array of EncodedCall structs containing information to execute the desired
     * number of low level calls
     * @param purchaseToken address of token used to transact - if address(0) ETH is used
     * @param price purchase price
     */
    function purchaseAsset(
        EncodedCall[] calldata calls,
        address purchaseToken,
        uint256 price
    ) external payable;

    /**
     * @notice ERC721 listing call made to arbitrary marketplace
     * @param calls encoded calls needed to list asset
     */
    function listAsset(EncodedCall[] memory calls) external;

    /**
     * @notice accept bid call made to arbitrary marketplace
     * @param calls encoded calls needed to accept bid
     */
    function acceptAssetBid(EncodedCall[] memory calls) external;

    /**
     * @notice accept bid call made to arbitrary marketplace
     * @param calls encoded calls needed to accept bid
     * @return proceeds amount of ETH forwarded to msg.sender (which is the owner)
     */
    function forwardSaleProceeds(
        EncodedCall[] memory calls
    ) external payable returns (uint256 proceeds);
}
