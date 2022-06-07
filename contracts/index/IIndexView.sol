// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Infra Index View Interface
 */
interface IIndexView {
    /**
     * @notice function to return the id of the Balancer Investment Pool corresponding to a target index
     * @dev useful for querying properties of the Investment Pool underlying the index
     * @return poolId
     */
    function getPoolId() external view returns (bytes32);

    /**
     * @notice function to return the address of the underlying Balancer Investment Pool
     * corresponding to the Insrt-Index
     * @return poolAddress the address of the Balancer Investment Pool
     */
    function getPool() external view returns (address poolAddress);
}
