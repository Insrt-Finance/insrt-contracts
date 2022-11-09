// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';

/**
 * @title Balancer Asset interface
 * @dev Empty interface used by balancer. For more info: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/interfaces/contracts/vault/IAsset.sol
 */
interface IAsset {

}

/**
 * @title Balancer Vault interface
 * @notice Required for pragma version workaround.
 * @dev Critical functions for interacting with the balancer vault.  For more info: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/interfaces/contracts/vault/IVault.sol
 */
interface IVault {
    /**
     * @notice function to join any Balancer Pool
     * @param poolId the id of the Balancer Pool
     * @param sender the sender of the tokens required to join the Balancer Pool
     * @param recipient the recipient of 'benefits' (ie Balancer Pool Tokens as shares) for joining the Balancer Pool
     * @param request a struct containing specific data pertaining to the join
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    /**
     * @notice struct containing specific data pertaining to a Balancer Pool join
     * @param assets an array of token addresses wrapped as a Balancer Vault Asset
     * @param maxAmountsIn the maximum amount to be deposited for each underyling Balancer Pool token
     * @param userData encoded data pertaining to the particular type of Join
     * @param fromInternalBalance boolean indicating whether funds are coming from a user's internal Balancer Vault balance
     */
    struct JoinPoolRequest {
        IERC20[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @notice function to exit any Balancer Pool
     * @param poolId the id of the Balancer Pool
     * @param sender the sender of the Balancer Pool Tokens required to exit the Balancer Pool
     * @param recipient the recipient of underlying Balancer Pool tokens, received for redeeming Balancer Pool Shares
     * @param request a struct containing specific data pertaining to the exit
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    /**
     * @notice struct containing specific data pertaining to a Balancer Pool exit
     * @param assets an array of token addresses wrapped as a Balancer Vault Asset
     * @param minAmountsOut the minimum amount to be received of each underyling Balancer Pool token
     * @param userData encoded data pertaining to the particular type of Exit
     * @param toInternalBalance boolean indicating whether funds are to be sent to a user's internal Balancer Vault balance
     */
    struct ExitPoolRequest {
        IERC20[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @notice function to return information related to an underlying token in a Balancer Pool
     * @param poolId the id of the pool to query
     * @param token the token to query for
     * @return cash the cash amount of token
     * @return managed the managed amount of token
     * @return lastChangeBlock the block in which the balances of the Balancer's pool underlying tokens last changed
     * @return assetManager the address responsible for managing cash/managed values
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @notice function to return underlying token info of a Balancer Pool
     * @param poolId the id of the Balancer Pool
     * @return tokens an array of underlying Balancer Pool token addresses
     * @return balances an array of the balances of each of the underlying Balancer Pool tokens
     * @return lastChangeBlock the block in which the balances of the Balancer's pool underlying tokens last changed
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @notice enum to depict the specialization of any Balancer Pool
     * @param GENERAL indicates a GENERAL specialization
     * @param MINIMAL_SWAP_INFO indicates a MINIMAL_SWAP_INFO specialization
     * @param TWO_TOKEN indicates a TWO_TOKEN specialization
     */
    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    /**
     * @notice funciton to return Balancer Pool info based on the poolId
     * @param poolId the id of the Balancer Pool
     * @return address the address of the Balancer Pool
     * @return PoolSpecialization the specialization of the Balancer Pool
     */
    function getPool(bytes32 poolId)
        external
        view
        returns (address, PoolSpecialization);
}
