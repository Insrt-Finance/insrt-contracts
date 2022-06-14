// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Infra Index View Interface
 */
interface IIndexView {
    /**
     * @notice get the ID of the underlying Balancer pool
     * @return Balancer pool ID
     */
    function getPoolId() external view returns (bytes32);

    /**
     * @notice get the exit fee in basis points
     * @return exitFee of the Index
     */
    function getExitFee() external view returns (uint16);
}
