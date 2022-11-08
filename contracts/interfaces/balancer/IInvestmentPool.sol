// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

/**
 * @title Custom interface to interact with Balancer InvestmentPool
 * @dev This is a combination of Balancer interfaces (IBasePool) and a custom one made for investment pools specifically.
 * No investment pool interface was found on balancer.
 */
interface IInvestmentPool {
    /**
     * @notice fetches pool id from balancer vault
     * @return bytes32 the poolId
     */
    function getPoolId() external view returns (bytes32);

    /**
     * @notice struct for different types of joins for weighted pools
     * @dev used when executing _doJoin and _onJoin in Balancer's InvestmentPool
     */
    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT,
        ADD_TOKEN
    }

    /**
     * @notice struct for different types of exits for weighted pools
     * @dev used when executing _doExit and _onExit in Balancer's InvestmentPool
     */
    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        REMOVE_TOKEN
    }

    /**
     * @notice function to set whether swaps are enabled on the underlying Balancer InvestmentPool
     * @param swapEnabled the boolean determining whether swaps will be enabled
     */
    function setSwapEnabled(bool swapEnabled) external;

    /**
     * #@notice function to return whether swaps are enabled in the underlying Balancer Investment pool
     * @return bool to indicate whether swaps are enabled
     */
    function getSwapEnabled() external view returns (bool);

    /**
     * @notice function to return the management swap fee %
     * @return uint256 the management swap fee %
     */
    function getManagementSwapFeePercentage() external view returns (uint256);

    /**
     * @notice function to returnt he minimum weight change duration
     * @dev this exists in order for the weights of underlying to not change too rapidly, and
     * potentially lead to massive arbitrage opportunities in the pools, harming it in the process
     * @return timestep in time-stamp format of the minimum weight change duration
     */
    function getMinimumWeightChangeDuration() external pure returns (uint256);

    /**
     * @notice function to update the weights of the Balancer InvestmentPool underlying tokens
     * @param startTime the timestamp for the weight update to begin
     * @param endTime the timestamp at which the weight update should be complete
     * @param endWeights the final weights of the underlying InvestmentPool tokens
     */
    function updateWeightsGradually(
        uint256 startTime,
        uint256 endTime,
        uint256[] memory endWeights
    ) external;

    /**
     * @notice function to return the current graduat weight update parameters
     * @return startTime the timestamp for the weight update to begin
     * @return endTime the timestamp at which the weight update should be complete
     * @return endWeights the final weights of the underlying InvestmentPool tokens
     */
    function getGradualWeightUpdateParams()
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256[] memory endWeights
        );

    /**
     * @notice function to return the Balancer Investment Pool's current token weights
     * @return weights of the Balancer Investment Pool's underlying tokens
     */
    function getNormalizedWeights() external view returns (uint256[] memory);

    /**
     * @notice function to return the total fees for management, earned via swaps
     * @return tokens the underlying Balancer InvestmentPool tokens
     * @return collectedFees the collected fees per token
     */
    function getCollectedManagementFees()
        external
        view
        returns (IERC20[] memory tokens, uint256[] memory collectedFees);

    /**
     * @notice function to withdraw the collected management fees for each underlying Balancer InvestmentPool token
     * @param recipient the address to which the fees go to
     */
    function withdrawCollectedManagementFees(address recipient) external;
}
