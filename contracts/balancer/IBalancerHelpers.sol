// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IVault } from './IVault.sol';

/**
 * @title Custom interface to retrieve useful information on joining/exiting investment pool
 */
interface IBalancerHelpers {
    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        IVault.JoinPoolRequest memory request
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        IVault.ExitPoolRequest memory request
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);
}
