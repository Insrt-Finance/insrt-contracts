// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Custom interface to interact with Balancer InvestmentPool
 * @dev This is a combination of Balancer interfaces (IBasePool) and a custom one made for investment pools specifically.
 * No investment pool interface was found on balancer.
 */
interface IInvestmentPool {
    function getPoolId() external view returns (bytes32);
}
