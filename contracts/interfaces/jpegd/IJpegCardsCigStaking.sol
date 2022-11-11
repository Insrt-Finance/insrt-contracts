// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IJpegCardsCigStaking {
    struct UserData {
        uint256 stakedCig;
        bool isStaking;
    }

    /// @notice Allows users to deposit one of their cigarette JPEG cards.
    /// @param _idx The index of the NFT to stake.
    function deposit(uint256 _idx) external;

    /// @notice Allows users to withdraw their staked cigarette JPEG card.
    /// @param _idx The index of the NFT to unstake.
    function withdraw(uint256 _idx) external;

    // @return Whether the user is staking a cigarette or not.
    function isUserStaking(address _user) external view returns (bool);

    /**
     * @notice custom getter for user data
     * @param user user address
     * @return UserData UserData struct
     */
    function userData(address user) external view returns (UserData memory);

    /**
     * @notice custom getter for jpeg'd card collection
     * @return address of jpeg'd card collection
     */
    function cards() external view returns (address);
}
