// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Interface to jpeg'd NFTVault Contracts
 * @dev https://github.com/jpegd/core/blob/main/contracts/vaults/NFTVault.sol
 */
interface INFTVault {
    enum BorrowType {
        NOT_CONFIRMED,
        NON_INSURANCE,
        USE_INSURANCE
    }

    struct Position {
        BorrowType borrowType;
        uint256 debtPrincipal;
        uint256 debtPortion;
        uint256 debtAmountForRepurchase;
        uint256 liquidatedAt;
        address liquidator;
    }

    /// @notice Allows users to open positions and borrow using an NFT
    /// @dev emits a {Borrowed} event
    /// @param _nftIndex The index of the NFT to be used as collateral
    /// @param _amount The amount of PUSD to be borrowed. Note that the user will receive less than the amount requested,
    /// the borrow fee and insurance automatically get removed from the amount borrowed
    /// @param _useInsurance Whether to open an insured position. In case the position has already been opened previously,
    /// this parameter needs to match the previous insurance mode. To change insurance mode, a user needs to close and reopen the position
    function borrow(
        uint256 _nftIndex,
        uint256 _amount,
        bool _useInsurance
    ) external;

    /// @param _nftIndex The NFT to return the value of
    /// @return The value in USD of the NFT at index `_nftIndex`, with 18 decimals.
    function getNFTValueUSD(uint256 _nftIndex) external view returns (uint256);

    /// @param _nftIndex The NFT to check
    /// @return The PUSD debt interest accumulated by the NFT at index `_nftIndex`.
    function getDebtInterest(uint256 _nftIndex) external view returns (uint256);

    /// @return The floor value for the collection, in ETH.
    function getFloorETH() external view returns (uint256);

    /// @notice Allows users to repay a portion/all of their debt. Note that since interest increases every second,
    /// a user wanting to repay all of their debt should repay for an amount greater than their current debt to account for the
    /// additional interest while the repay transaction is pending, the contract will only take what's necessary to repay all the debt
    /// @dev Emits a {Repaid} event
    /// @param _nftIndex The NFT used as collateral for the position
    /// @param _amount The amount of debt to repay. If greater than the position's outstanding debt, only the amount necessary to repay all the debt will be taken
    function repay(uint256 _nftIndex, uint256 _amount) external;

    /// @notice Allows a user to close a position and get their collateral back, if the position's outstanding debt is 0
    /// @dev Emits a {PositionClosed} event
    /// @param _nftIndex The index of the NFT used as collateral
    function closePosition(uint256 _nftIndex) external;

    /**
     * @notice explicit getter for positions for a given NFT token id
     * @return Position for the given NFT token id
     */
    function positions(uint256 tokenId) external view returns (Position memory);
}
