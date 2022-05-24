// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

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
}
