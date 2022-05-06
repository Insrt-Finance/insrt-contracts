// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

interface IIndexManager {
    event IndexDeployed(address deployment);

    function INDEX_DIAMOND() external view returns (address);

    function INVESTMENT_POOL_FACTORY() external view returns (address);

    /**
     * @notice TODO
     */
    function deployIndex(
        IERC20[] calldata tokens,
        uint256[] calldata weights,
        uint16 depositFee,
        uint16 withdrawalFee,
        uint16 swapFee
    ) external returns (address deployment);
}
