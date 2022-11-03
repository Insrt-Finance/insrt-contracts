// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Interface to jpeg'd Vault Contracts
 * @dev https://github.com/jpegd/core/blob/main/contracts/vaults/erc20/Vault.sol
 * @dev Only whitelisted contracts may call these functions
 */
interface IVault {
    /// @notice Allows users to deposit `token`. Contracts can't call this function
    /// @param _to The address to send the tokens to
    /// @param _amount The amount to deposit
    function deposit(address _to, uint256 _amount)
        external
        returns (uint256 shares);

    /// @notice Allows users to withdraw tokens. Contracts can't call this function
    /// @param _to The address to send the tokens to
    /// @param _shares The amount of shares to burn
    function withdraw(address _to, uint256 _shares)
        external
        returns (uint256 backingTokens);

    /// @return The underlying tokens per share
    function exchangeRate() external view returns (uint256);

    /// jpeg'd RATE struct
    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    /**
     * @notice custom getter for depositFeeRate in jpeg'd citadel
     * @return Rate deposit fee rate
     */
    function depositFeeRate() external view returns (Rate memory);
}
