// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Interface to jpeg'd LPFarming Contracts
 * @dev https://github.com/jpegd/core/blob/main/contracts/farming/LPFarming.sol
 * @dev Only whitelisted contracts may call these functions
 */
interface ILPFarming {
    /// @notice Frontend function used to calculate the amount of rewards `_user` can claim from the pool with id `_pid`
    /// @param _pid The pool id
    /// @param _user The address of the user
    /// @return The amount of rewards claimable from `_pid` by user `_user`
    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    /// @notice Allows users to deposit `_amount` of LP tokens in the pool with id `_pid`. Non whitelisted contracts can't call this function
    /// @dev Emits a {Deposit} event
    /// @param _pid The id of the pool to deposit into
    /// @param _amount The amount of LP tokens to deposit
    function deposit(uint256 _pid, uint256 _amount) external;

    /// @notice Allows users to withdraw `_amount` of LP tokens from the pool with id `_pid`. Non whitelisted contracts can't call this function
    /// @dev Emits a {Withdraw} event
    /// @param _pid The id of the pool to withdraw from
    /// @param _amount The amount of LP tokens to withdraw
    function withdraw(uint256 _pid, uint256 _amount) external;

    /// @notice Allows users to claim rewards from the pool with id `_pid`. Non whitelisted contracts can't call this function
    /// @dev Emits a {Claim} event
    /// @param _pid The pool to claim rewards from
    function claim(uint256 _pid) external;

    /// @notice Allows users to claim rewards from all pools. Non whitelisted contracts can't call this function
    /// @dev Emits a {ClaimAll} event
    function claimAll() external;
}
