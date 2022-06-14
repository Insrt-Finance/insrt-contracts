// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

/**
 * @title Index Manager contract interface
 */
interface IIndexManager {
    /**
     * @notice event to be logged whenever an Insrt-Index is deployed
     * @param deployment the address of the deployed Insrt-Index
     */
    event IndexDeployed(address deployment);

    /**
     * @notice function to return the address of the Index Diamond contract
     * @return address of the Index Diamond
     */
    function INDEX_DIAMOND() external view returns (address);

    /**
     * @notice function to return the address of the Balancer InvestmentPoolFactory contract
     * @return address of the Balancer InvestmentPoolFactory
     */
    function INVESTMENT_POOL_FACTORY() external view returns (address);

    /**
     * @notice functio to deploy an Insrt-Index proxy
     * @param tokens the underlying tokens of the Insrt-Index
     * @param weights the weights of the underlying tokens of the Insrt-Index
     * @param amounts the amount of each underlying token given for the intialization of the underlying
     * Balancer Investment Pool
     * @param exitFee the fee to be applied on redeem of Insrt-Index shares
     * @return deployment the address of the Insrt-Index proxy
     */
    function deployIndex(
        IERC20[] calldata tokens,
        uint256[] calldata weights,
        uint256[] calldata amounts,
        uint16 exitFee
    ) external returns (address deployment);
}
