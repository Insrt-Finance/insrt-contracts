// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Interface to jpeg'd NFTVault Contracts
 * @dev https://github.com/jpegd/core/blob/main/contracts/vaults/NFTVault.sol
 */
interface INFTVault {
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

    /// @param _nftIndex The NFT to return the credit limit of
    /// @return The PUSD credit limit of the NFT at index `_nftIndex`.
    function getCreditLimit(uint256 _nftIndex) external view returns (uint256);
}
