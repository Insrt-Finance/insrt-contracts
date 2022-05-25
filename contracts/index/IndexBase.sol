// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { ERC4626 } from '@solidstate/contracts/token/ERC4626/ERC4626.sol';
import { ERC20MetadataInternal } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataInternal.sol';

import { IIndexBase } from './IIndexBase.sol';
import { IndexInternal } from './IndexInternal.sol';
import { IndexStorage } from './IndexStorage.sol';
import { IVault, IAsset } from '../balancer/IVault.sol';
import { IBalancerHelpers } from '../balancer/IBalancerHelpers.sol';
import { IInvestmentPool } from '../balancer/IInvestmentPool.sol';

/**
 * @title Infra Index base functions
 * @dev deployed standalone and referenced by IndexProxy
 */
contract IndexBase is IIndexBase, ERC4626, IndexInternal {
    using IndexStorage for IndexStorage.Layout;

    constructor(address balancerVault, address balancerHelpers)
        IndexInternal(balancerVault, balancerHelpers)
    {}

    /**
     * @notice function to initiliaze the Balancer InvestmentPool
     * @dev required to be called once otherwise all other deposits will be reverted
     * Ref: https://github.com/balancer-labs/balancer-v2-monorepo/blob/823f7fe7d3cb45f9bc6bcdfb83af3d70c050d1d2/pkg/pool-utils/contracts/BasePool.sol#L220
     * @param amountsIn the amounts of each token deposited
     * @param amountOut the amount of BPT expected to be received as a minimum
     */
    function intializePoolByDeposit(
        uint256[] memory amountsIn,
        uint256 amountOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest memory request = _constructJoinInitRequest(
            l,
            amountsIn
        );

        //TODO: perhaps amountOut may be set to 0 in this case?
        _performJoinAndMint(amountOut, l.poolId, request);
    }

    /**
     * @notice function to deposit an amount of tokens to Balancer InvestmentPool
     * @dev takes all investmentPool tokens at specified amounts, deposits
     * into InvestmentPool, receives BPT in exchange to store in insrt-index,
     * returns insrt-index shares to user
     * @param amounts the amounts of underlying tokens in balancer investmentPool
     * @param minBPTAmountOut the minimum amount of BPT expected to be given back
     */
    function userDepositExactInForAnyOut(
        uint256[] memory amounts,
        uint256 minBPTAmountOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest memory request = _constructJoinExactInRequest(
            l,
            amounts,
            minBPTAmountOut
        );

        _performJoinAndMint(minBPTAmountOut, l.poolId, request);
    }

    /**
     * @notice function to deposit a single token for shares in the Insrt-index
     * @dev takes a single investment pool token from the user, deposits into investment pool,
     * Insrt-index receives an exact (known) amount of BPT in exchange, user receives insrt-index
     * shares proportionally.
     * @param amounts the amounts of underlying tokens in Balancer InvestmentPool deposited -
     * could be a single token however call requests []
     * @param bptAmountOut the exact amount of BPT wanted by the user (translated to Insrt-index shares)
     * @param tokenIndex the index of the deposited token in the array of Assets.
     */
    function userDepositSingleForExactOut(
        uint256[] memory amounts,
        uint256 bptAmountOut,
        uint256 tokenIndex
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest memory request = _constructJoinSingleForExactRequest(
            l,
            amounts, //could perhaps be an empty array? Balancer will request the appropriate amount
            bptAmountOut,
            tokenIndex
        );

        _performJoinAndMint(bptAmountOut, l.poolId, request);
    }

    /**
     * @notice function to deposit any required amount of all tokens to receive an exact amount of
     * Insrt-index shares
     * @dev takes all investment pool tokens from the user, deposits into investment pool,
     * Insrt-index receives an exact (known) amount of BPT in exchange, user receives insrt-index
     * shares proportionally.
     * @param amounts the amounts of underlying tokens in Balancer InvestmentPool deposited
     * @param bptAmountOut the exact amount of BPT (Insrt-index) shares requested
     */
    function userDepositAllForExactOut(
        uint256[] memory amounts,
        uint256 bptAmountOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest
            memory request = _constructJoinAllForExactRequest(
                l,
                amounts,
                bptAmountOut
            );

        _performJoinAndMint(bptAmountOut, l.poolId, request);
    }

    /**
     * @notice function which burns insrt-index shares and returns underlying tokens in Balancer InvestmentPool
     * @dev applies a fee on the shares, and sends an amount of `remainingShares` of BPT from insrt-index
     * to Balancer InvestmentPool in exchange for tokens, sent to the user. Shares are burnt.
     * @param sharesOut the amount of shares the user wishes to withdraw
     * @param minAmountsOut the minimum amounts of tokens received for the withdraw
     */
    function userWithdrawExactForAll(
        uint256 sharesOut,
        uint256[] calldata minAmountsOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.ExitPoolRequest
            memory request = _constructExitExactForAllRequest(
                l,
                sharesOut,
                minAmountsOut
            );

        _performExitAndWithdraw(sharesOut, l.poolId, request);
    }

    /**
     * @notice function to withdraw Insrt-shares for a single underlying token
     * @dev applies a fee on the shares withdrawn, and sends an amount of `remainingSahres` of BPT from
     * insrt-index to Balancer Investment pool in exchange for the single token, send to user. Shares are burnt.
     * @param sharesOut the amount of shares the user wishes to withdraw
     * @param amountsOut the amounts of underlying token received in exchange for shares
     * @param tokenId the id of the token to be received
     */
    function userWithdrawExactForSingle(
        uint256 sharesOut,
        uint256[] memory amountsOut,
        uint256 tokenId
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.ExitPoolRequest
            memory request = _constructExitExactForSingleRequest(
                l,
                amountsOut,
                sharesOut,
                tokenId
            );

        _performExitAndWithdraw(sharesOut, l.poolId, request);
    }

    //TODO: Query other deposits
    //TODO: Modify name
    /**
     * @notice function to return the BPT given for a certain amount of underlying Balancer InvesmentPool tokens
     * @param amounts an array comprised of the amount of each underlying token
     * @param minBPTAmountOut the minimum amount of BPT accepted as a return
     * @return bptOut the BPT returned
     * @return amountsIn the amounts to be taken in by Balancer InvestmentPool for the BPT returned
     */
    function queryUserDepositExactIn(
        uint256[] memory amounts,
        uint256 minBPTAmountOut
    ) external returns (uint256 bptOut, uint256[] memory amountsIn) {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest memory request = _constructJoinExactInRequest(
            l,
            amounts,
            minBPTAmountOut
        );

        (bptOut, amountsIn) = IBalancerHelpers(BALANCER_HELPERS).queryJoin(
            l.poolId,
            address(this),
            address(this),
            request
        );
    }

    //TODO: Query other withdraws
    //TODO: Modify name
    /**
     * @notice function to return the amounts return for a certain BPT, and the BPT expected in for those amounts
     * @param sharesOut the amount of insrt-index shares a user wants to redeem
     * @param minAmountsOut the minimum amount of each token the user is willing to accept
     * @return bptIn the amount of BPT required for the amounts out
     * @return amountsOut the amount of each token returned for the BPT
     */
    function queryUserWithdrawExactForAll(
        uint256 sharesOut,
        uint256[] calldata minAmountsOut
    ) external returns (uint256 bptIn, uint256[] memory amountsOut) {
        IndexStorage.Layout storage l = IndexStorage.layout();

        IVault.ExitPoolRequest
            memory request = _constructExitExactForAllRequest(
                l,
                sharesOut,
                minAmountsOut
            );

        (bptIn, amountsOut) = IBalancerHelpers(BALANCER_HELPERS).queryExit(
            l.poolId,
            address(this),
            msg.sender,
            request
        );
    }

    //IBalancerHelpers(BALANCER_HELPERS).queryExit(l.poolId, address(this), msg.sender, request);

    /**
     * @notice function to call joinPool in Balancer Vault and mint Insrt-index shares to user
     * @dev used for all joins as the functionality is common
     * @param amountOut the expected BPT amount to come form the join
     * @param poolId the id of the Balancer investment pool
     * @param request the JoinPoolRequest struct to pass into the joinPool call
     */
    function _performJoinAndMint(
        uint256 amountOut,
        bytes32 poolId,
        IVault.JoinPoolRequest memory request
    ) internal {
        //Check this contract is an approved relayer for user
        //If not, approve. Required so that in joinPool call, tokenized
        //shares are sent to Insrt-Index, and user transfers to Balancer Vault
        //directly.
        //Ref: https://github.com/balancer-labs/balancer-v2-monorepo/blob/a9b1e969a19c4f93c14cd19fba45aaa25b015d12/pkg/vault/contracts/interfaces/IVault.sol#L348
        _checkBalancerRelayerStatus();

        //TODO: Is there a potential mismatch of results between queryJoin and joinPool?
        (uint256 bptOut, ) = IBalancerHelpers(BALANCER_HELPERS).queryJoin(
            poolId,
            msg.sender,
            address(this),
            request
        );

        //TODO: Is amountsIn (2nd return variable by `queryJoin`) a better check than BPT Out?
        //TODO: Check if balancer contains internal check
        require(
            bptOut >= amountOut,
            'Not enough tokens provided for desired BPT out'
        );

        IVault(BALANCER_VAULT).joinPool(
            poolId,
            msg.sender,
            address(this),
            request
        );
        //Mint shares to joining user
        _mint(bptOut, msg.sender);
    }

    /**
     * @notice function to call exitPool in Balancer vault, and withdraw/burn Insrt-index shares of user
     * @dev used for all exits as the functionality is common
     * @param sharesOut the amounts
     */
    function _performExitAndWithdraw(
        uint256 sharesOut,
        bytes32 poolId,
        IVault.ExitPoolRequest memory request
    ) internal {
        //TODO: confirm this does not drain vault
        IVault(BALANCER_VAULT).exitPool(
            poolId,
            address(this),
            payable(msg.sender),
            request
        );

        _withdraw(sharesOut, msg.sender, msg.sender);
    }

    //TODO: find better way to check if there is a relayer for each user to reduce gas checks?
    /**
     * @notice function to check the relayer approval for each user via Balancer of the Insrt-Index
     */
    function _checkBalancerRelayerStatus() internal {
        if (
            !IVault(BALANCER_VAULT).hasApprovedRelayer(
                msg.sender,
                address(this)
            )
        ) {
            //Ref: https://github.com/balancer-labs/balancer-v2-monorepo/blob/9eb179da66c4f47c795b7b86479c3f13411c027d/pkg/vault/contracts/VaultAuthorization.sol#L116
            IVault(BALANCER_VAULT).setRelayerApproval(
                msg.sender,
                address(this),
                true
            );
        }
    }

    /**
     * @notice function to construct the request needed to initialize a Balancer InvestmentPool
     * @dev only works for JoinKind.INIT
     * @param l the index layout
     * @param amountsIn the amounts of tokens deposited
     * @return request a JoinPoolRequest constructed for INIT JoinKind
     */
    function _constructJoinInitRequest(
        IndexStorage.Layout storage l,
        uint256[] memory amountsIn
    ) internal view returns (IVault.JoinPoolRequest memory request) {
        IInvestmentPool.JoinKind kind = IInvestmentPool.JoinKind.INIT;

        bytes memory userData = abi.encode(kind, amountsIn);
        request = _constructJoinRequest(l.tokens, amountsIn, userData);
    }

    /**
     * @notice function to construct the request needed for a user to deposit in an insrt-index
     * @dev only works for JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT
     * @param l the index layout
     * @param amounts an array comprised of the amount of each underlying token
     * @param minBPTAmountOut the minimum amount of BPT accepted as a return
     * @return request a JoinPoolRequest constructed for EXACT_TOKENS_IN_FOR_BPT_OUT JoinKind
     */
    function _constructJoinExactInRequest(
        IndexStorage.Layout storage l,
        uint256[] memory amounts,
        uint256 minBPTAmountOut
    ) internal view returns (IVault.JoinPoolRequest memory request) {
        IInvestmentPool.JoinKind kind = IInvestmentPool
            .JoinKind
            .EXACT_TOKENS_IN_FOR_BPT_OUT;
        //To perform an Join of kind `EXACT_TOKENS_IN_FOR_BPT_OUT` the `userData` variable
        //must contain the encoded "kind" of join, and the amounts of tokens given for the joins, and
        //the minBPTAmountOut.
        //Ref: https://github.com/balancer-labs/balancer-v2-monorepo/blob/d2794ef7d8f6d321cde36b7c536e8d51971688bd/pkg/interfaces/contracts/pool-weighted/WeightedPoolUserData.sol#L49
        bytes memory userData = abi.encode(kind, amounts, minBPTAmountOut);

        request = _constructJoinRequest(l.tokens, amounts, userData);
    }

    /**
     * @notice function to construct the request needed for a user to deposit a single token in an insert-index
     * @dev only works for JoinKind.TOKEN_IN_FOR_EXACT_BPT_OUT
     * @param l the index layout
     * @param amounts an array comprised of the amount of each token provided (note: this would be of length 1 in this case)
     * @param bptAmountOut the exact amount of BPT to be returned for the sinlge token join
     * @param tokenIndex the index of the underyling token in the tokens array
     * @return request a JoinPoolRequest constructed for TOKEN_IN_FOR_EXACT_BPT_OUT
     */
    function _constructJoinSingleForExactRequest(
        IndexStorage.Layout storage l,
        uint256[] memory amounts,
        uint256 bptAmountOut,
        uint256 tokenIndex
    ) internal view returns (IVault.JoinPoolRequest memory request) {
        IInvestmentPool.JoinKind kind = IInvestmentPool
            .JoinKind
            .TOKEN_IN_FOR_EXACT_BPT_OUT;

        bytes memory userData = abi.encode(kind, bptAmountOut, tokenIndex);

        request = _constructJoinRequest(l.tokens, amounts, userData);
    }

    /**
     * @notice function to construct the request needed for a user to deposit all underlying tokens
     * in an Insrt-Index, for an exact amount of BPT out
     * @dev only works for JoinKind.ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
     * @param l the index layout
     * @param amounts the amounts of each underlying token provided
     * @param bptAmountOut the exact BPT expected
     * @return request a JoinPoolRequest constructed for ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
     */
    function _constructJoinAllForExactRequest(
        IndexStorage.Layout storage l,
        uint256[] memory amounts,
        uint256 bptAmountOut
    ) internal view returns (IVault.JoinPoolRequest memory request) {
        IInvestmentPool.JoinKind kind = IInvestmentPool
            .JoinKind
            .ALL_TOKENS_IN_FOR_EXACT_BPT_OUT;

        bytes memory userData = abi.encode(kind, bptAmountOut);

        request = _constructJoinRequest(l.tokens, amounts, userData);
    }

    //TODO: How to apply fee?
    function _constructExitExactOutRequest(
        IndexStorage.Layout storage l,
        uint256[] memory amountsOut,
        uint256 maxBPTAmountIn
    ) internal view returns (IVault.ExitPoolRequest memory request) {
        IInvestmentPool.ExitKind kind = IInvestmentPool
            .ExitKind
            .BPT_IN_FOR_EXACT_TOKENS_OUT;

        bytes memory userData = abi.encode(kind, amountsOut, maxBPTAmountIn);

        request = _constructExitRequest(l.tokens, amountsOut, userData);
    }

    /**
     * @notice function to construct the request needed for a user to withdraw shares of
     * the Insrt-Index, for a single token returned
     * @dev only works for ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT
     * @param l the index layout
     * @param amountsOut the amounts of each underlying token returned | perhaps not needed
     * @param bptAmountIn the BPT withdrawn from the pool
     * @param tokenId the tokenId of the token to be returned
     * @return request an ExitPoolRequest constructed for EXACT_BPT_IN_FOR_ONE_TOKEN_OUT
     */
    function _constructExitExactForSingleRequest(
        IndexStorage.Layout storage l,
        uint256[] memory amountsOut, //perhaps not needed
        uint256 bptAmountIn,
        uint256 tokenId
    ) internal view returns (IVault.ExitPoolRequest memory request) {
        IInvestmentPool.ExitKind kind = IInvestmentPool
            .ExitKind
            .BPT_IN_FOR_EXACT_TOKENS_OUT;

        (uint256 feeBpt, uint256 remainingBPTIn) = _applyFee(
            l.exitFee,
            bptAmountIn
        );

        bytes memory userData = abi.encode(kind, remainingBPTIn, tokenId);

        request = _constructExitRequest(l.tokens, amountsOut, userData);
    }

    /**
     * @notice function to construct the request needed for a user to redeem a certain amount of insrt-index shares
     * @dev only works for ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT
     * @param sharesOut the amount of insrt-index shares a user wants to redeem
     * @param minAmountsOut the minimum amount of each token the user is willing to accept
     * @return request an ExitPoolRequest constructed for EXACT_BPT_IN_FOR_TOKENS_OUT ExitKind
     */
    function _constructExitExactForAllRequest(
        IndexStorage.Layout storage l,
        uint256 sharesOut,
        uint256[] memory minAmountsOut
    ) internal view returns (IVault.ExitPoolRequest memory request) {
        //Maybe this should be accounted for somewhere? Automatically done by balanceOf bpt tokens?
        (uint256 feeBpt, uint256 remainingSharesOut) = _applyFee(
            l.exitFee,
            sharesOut
        );
        IInvestmentPool.ExitKind kind = IInvestmentPool
            .ExitKind
            .EXACT_BPT_IN_FOR_TOKENS_OUT;
        //To perform an Exit of kind `EXACT_BPT_IN_FOR_TOKENS_OUT` the `userData` variable
        //must contain the encoded "kind" of exit, and the amount of BPT to "exit" from the
        //pool.
        bytes memory userData = abi.encode(kind, remainingSharesOut);

        request = _constructExitRequest(l.tokens, minAmountsOut, userData);
    }

    /**
     * @notice function to construct arbitrary join request
     * @dev fromInternalBalance always set to false as the assumption is made that the user will not
     * seek to use tokens they have already deposited elsewhere in Balancer Vault
     * Ref: https://github.com/balancer-labs/balancer-v2-monorepo/blob/a9b1e969a19c4f93c14cd19fba45aaa25b015d12/pkg/vault/contracts/interfaces/IVault.sol#L364
     * @param tokens the array of tokens to convert to assets
     * @param maxAmountsIn the maximum amounts of tokens provided for the join
     * @param userData the userData for the join request
     * @return joinRequest the constructed JoinPoolRequest
     */
    function _constructJoinRequest(
        IERC20[] memory tokens,
        uint256[] memory maxAmountsIn,
        bytes memory userData
    ) internal pure returns (IVault.JoinPoolRequest memory joinRequest) {
        joinRequest.assets = _tokensToAssets(tokens);
        joinRequest.maxAmountsIn = maxAmountsIn;
        joinRequest.userData = userData;
        joinRequest.fromInternalBalance = false;
    }

    /**
     * @notice function to construct an arbitrary exit request
     * @dev fromInternalBalance always set to false as the assumption is made that the user will not
     * seek to send/keep tokens elsewhere in Balancer Vault.
     * Ref: https://github.com/balancer-labs/balancer-v2-monorepo/blob/a9b1e969a19c4f93c14cd19fba45aaa25b015d12/pkg/vault/contracts/interfaces/IVault.sol#L410
     * @param tokens the array of tokens to convert to assets
     * @param minAmountsOut the minimum amounts of tokens given for the BPT provided
     * @param userData the userData for the exit request
     * @return exitRequest the constructed ExitPoolRequest
     */
    function _constructExitRequest(
        IERC20[] memory tokens,
        uint256[] memory minAmountsOut,
        bytes memory userData
    ) internal pure returns (IVault.ExitPoolRequest memory exitRequest) {
        exitRequest.assets = _tokensToAssets(tokens);
        exitRequest.minAmountsOut = minAmountsOut;
        exitRequest.userData = userData;
        exitRequest.toInternalBalance = false;
    }

    /**
     * @notice function to check whether userInput amounts of tokens are enough to perform a Join
     * to a Balancer pool
     * @param userInputs the amounts of tokens provided
     * @param queryResults the queried result for amounts needed to perform join
     */
    function _checkJoinAmounts(
        uint256[] memory userInputs,
        uint256[] memory queryResults
    ) internal pure {
        uint256 length = userInputs.length;
        for (uint256 i; i < length; ) {
            require(
                userInputs[i] >= queryResults[i],
                'Not enough tokens for Balancer Join'
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _name()
        internal
        view
        override(ERC20MetadataInternal, IndexInternal)
        returns (string memory)
    {
        return super._name();
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _symbol()
        internal
        view
        override(ERC20MetadataInternal, IndexInternal)
        returns (string memory)
    {
        return super._symbol();
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _decimals()
        internal
        pure
        override(ERC20MetadataInternal, IndexInternal)
        returns (uint8)
    {
        return super._decimals();
    }
}
