// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IVault } from './IVault.sol';

/**
 * @title Custom interface to interact with Balancer InvestmentPool
 * @dev This is a combination of Balancer interfaces (IBasePool) and a custom one made for investment pools specifically.
 * No investment pool interface was found on balancer.
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
