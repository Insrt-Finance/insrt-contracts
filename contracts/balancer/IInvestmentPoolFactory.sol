// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

/**
 * @title Balancer InvestmentPoolFactory interface
 */
interface IInvestmentPoolFactory {
    /**
     * @notice function to create a Balancer Investment Pool
     * @param name of the Balancer Investment Pool Token
     * @param symbol of the Balancer Investment Pool Token
     * @param tokens addresses of the underlying tokens of the Balancer Investment Pool
     * @param weights of each of the underlying tokens of the Balancer Investment Pool
     * @param swapFeePercentage the percentage of the fee applied to each swap sent to the Balancer Vault protocolFeeCollector
     * @param owner the owner of the Balancer Investment Pool
     * @param swapEnabledOnStart boolean to indicate whether swaps should be enabled on deployment
     * @param managementSwapFeePercentage percentage of swap fees that are allocated to the Pool owner
     * @return address of the deployed Balancer Investment Pool
     */
    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256[] memory weights,
        uint256 swapFeePercentage,
        address owner,
        bool swapEnabledOnStart,
        uint256 managementSwapFeePercentage
    ) external returns (address);
}
