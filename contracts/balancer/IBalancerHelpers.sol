// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IVault } from './IVault.sol';

/**
 * @title Custom interface to retrieve useful information on joining/exiting investment pool
 */
interface IBalancerHelpers {
    /**
     * @notice function to query a Balancer Pool join without executing it to receiving information on its returns/requirements
     * @param poolId the id of the Balancer Pool
     * @param sender the sender of the tokens required to join the Balancer Pool
     * @param recipient the recipient of 'benefits' (ie Balancer Pool Tokens as shares) for joining the Balancer Pool
     * @param request a struct containing specific data pertaining to the join
     * @return bptOut the amount of Balancer Pool Tokens returned for the join
     * @return amountsIn the amount of each underlying Balancer Pool token required for the join
     */
    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        IVault.JoinPoolRequest memory request
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    /**
     * @notice function to query a Balancer Pool exit without executing it to receiving information on its returns/requirements
     * @param poolId the id of the Balancer Pool
     * @param sender the sender of the Balancer Pool Tokens required to exit the Balancer Pool
     * @param recipient the recipient of underlying Balancer Pool tokens, received for redeeming Balancer Pool Shares
     * @param request a struct containing specific data pertaining to the exit
     * @return bptIn the amount of Balancer Pool Tokens given for the exit
     * @return amountsOut the amount of each underlying Balancer Pool token returned for the exit
     */
    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        IVault.ExitPoolRequest memory request
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);
}
