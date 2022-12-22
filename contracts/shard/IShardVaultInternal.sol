// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IOwnableInternal } from '@solidstate/contracts/access/ownable/IOwnableInternal.sol';

interface IShardVaultInternal is IOwnableInternal {
    struct JPEGParams {
        address PUSD;
        address PETH;
        address JPEG;
        address JPEG_CARDS_CIG_STAKING;
        address PUSD_CITADEL;
        address PETH_CITADEL;
        address CURVE_PUSD_POOL;
        address CURVE_PETH_POOL;
        address LP_FARM;
    }

    struct AuxiliaryParams {
        address PUNKS;
        address DAWN_OF_INSRT;
        address MARKETPLACE_HELPER;
        address TREASURY;
    }

    /**
     * @notice thrown when the deposit amount is not a multiple of shardSize
     */
    error ShardVault__InvalidDepositAmount();

    /**
     * @notice thrown when the maximum capital has been reached or vault has invested
     */
    error ShardVault__DepositForbidden();

    /**
     * @notice thrown when the withdraw amount exceeds the owed shards to the sender
     */
    error ShardVault__InsufficientShards();

    /**
     * @notice thrown when the maximum capital has been reached or vault has invested
     */
    error ShardVault__WithdrawalForbidden();

    /**
     * @notice thrown when attempt to purchase a punk is made when collection is not punks
     */
    error ShardVault__CollectionNotPunks();

    /**
     * @notice thrown when attempting to act on an unowned asset
     */
    error ShardVault__NotOwned();

    /**
     * @notice thrown when setting a basis point fee value larger than 10000
     */
    error ShardVault__BasisExceeded();

    /**
     * @notice thrown when function called by non-protocol owner
     */
    error ShardVault__NotProtocolOwner();

    /**
     * @notice thrown when function called by non-authorized account
     */
    error ShardVault__NotAuthorized();

    /**
     * @notice thrown when function called by non-shard owner
     */
    error ShardVault__NotShardOwner();

    /**
     * @notice thrown when attempting to borrow after target LTV amount is reached
     */
    error ShardVault__TargetLTVReached();

    /**
     * @notice thrown when attempting to act without being whitelisted
     */
    error ShardVault__NotWhitelisted();

    /**
     * @notice thrown when attempting to call a disabled function
     */
    error ShardVault__NotEnabled();

    /**
     * @notice thrown when attempting to set whitelist deadline without setting reserved shards
     */
    error ShardVault__NoReservedShards();

    /**
     * @notice thrown when user is attempting to deposit after owning (minting) max shards
     */
    error ShardVault__MaxMintBalance();

    /**
     * @notice thrown when caller is not shard collection
     */
    error ShardVault__NotShardCollection();

    /**
     * @notice thrown when the actual downpayment amount is too small
     */
    error ShardVault__DownPaymentInsufficient();

    /**
     * @notice thrown when the vault is meant to handle PUSD but is called a PETH function or vice versa
     */
    error ShardVault__CallTypeProhibited();

    /**
     * @notice thrown when attempting to claim yield before yield claiming is initialized
     */
    error ShardVault__YieldClaimingForbidden();

    /**
     * @notice thrown when attempting to claim excess ETH after yield claiming is initialized
     */
    error ShardVault__ClaimingExcessETHForbidden();

    /**
     * @notice thrown when attempting to withdraw fees with treasury address == address(0)
     */
    error ShardVault__TreasuryIsZeroAddress();

    /**
     * @notice thrown when attempting to set a reserved supply larger than max supply
     */
    error ShardVault__ExceededMaxSupply();

    /**
     * @notice thrown when setting a max supply which is smaller than total supply
     */
    error ShardVault__MaxSupplyTooSmall();

    /**
     * @notice thrown when attempting to reduce yield fee whilst not owning DawnOfInsrt token used to reduce yield fee
     */
    error ShardVault__NotDawnOfInsrtTokenOwner();

    /**
     * @notice emitted when baseURI is set
     * @param baseURI the new baseURI for ERC721Metadata
     */
    event SetBaseURI(string baseURI);

    /**
     * @notice emitted when whitelistEndsAt is set
     * @param whitelistEndsAt the new whitelistEndsAt timestamp
     */
    event SetWhitelistEndsAt(uint48 whitelistEndsAt);

    /**
     * @notice emitted when reservedSupply is set
     * @param reservedSupply the new reservedSupply
     */
    event SetReservedSupply(uint64 reservedSupply);

    /**
     * @notice emitted when isEnabled is set
     * @param isEnabled the new isEnabled value
     */
    event SetIsEnabled(bool isEnabled);

    /**
     * @notice emitted when maxMintBalance is set
     * @param maxMintBalance the new maxMintBalance
     */
    event SetMaxMintBalance(uint64 maxMintBalance);

    /**
     * @notice emitted when maxSupply is set
     * @param maxSupply the new maxSupply
     */
    event SetMaxSupply(uint64 maxSupply);

    /**
     * @notice emitted when protocol fees are withdrawn
     * @param feesETH amount of ETH withdrawn as fees
     * @param feesJPEG amount of JPEG withdrawn as fees
     */
    event WithdrawFees(uint256 feesETH, uint256 feesJPEG);

    /**
     * @notice emitted when sale fee is set
     * @param feeBP the new sale fee basis points
     */
    event SetSaleFee(uint16 feeBP);

    /**
     * @notice emitted when acquisition fee is set
     * @param feeBP the new acquisition fee basis points
     */
    event SetAcquisitionFee(uint16 feeBP);

    /**
     * @notice emitted when yield fee is set
     * @param feeBP the new yield fee basis points
     */
    event SetYieldFee(uint16 feeBP);

    /**
     * @notice emitted when the authorized status of an account is set
     * @param account address of account
     * @param isAuthorized authorized status
     */
    event SetAuthorized(address account, bool isAuthorized);

    /**
     * @notice emitted when a punk is purchased by the vault
     * @param punkId purchased punk id
     */
    event PurchasePunk(uint256 punkId);

    /**
     * @notice emitted when unused ETH is made available to claim
     */
    event MakeUnusedETHClaimable();

    /**
     * @notice emitted when a punk is collateralized for pUSD
     * @param pUSD received pUSD for collateralization
     */
    event CollateralizePunkPUSD(uint256 pUSD);

    /**
     * @notice emitted when a punk is collateralized for pETH
     * @param pETH received pETH for collateralization
     */
    event CollaterlizePunkPETH(uint256 pETH);

    /**
     * @notice emitted when PUSD is staked
     * @param shares lpFarm shares received after 3rd staking stage
     */
    event StakePUSD(uint256 shares);

    /**
     * @notice emitted when PETH is staked
     * @param shares lpFarm shares received after 3rd staking stage
     */
    event StakePETH(uint256 shares);
    /**
     * @notice emitted when part of the position in unstaked and a PUSD loan is repaid
     * @param paidDebt amount of PUSD debt paid
     */
    event RepayLoanPUSD(uint256 paidDebt);

    /**
     * @notice emitted when part of the position in unstaked and a PETH loan is repaid
     * @param paidDebt amount of PETH debt paid
     */
    event RepayLoanPETH(uint256 paidDebt);

    /**
     * @notice emitted when a direct loan repayment is made
     * @param token address of JPEG 'stablecoin' used for repayment
     * @param amount amount of 'stablecoin' repaid
     * @param punkId id of punk for which debt is reduced
     */
    event DirectRepayLoan(address token, uint256 amount, uint256 punkId);

    /**
     * @notice emitted when a JPEG position of a punk in a PETH vault is closed
     * @param punkId id of punk
     * @param receivedETH ETH received when surplus PETH is converted
     */
    event ClosePunkPositionPETH(uint256 punkId, uint256 receivedETH);

    /**
     * @notice emitted when a bid is accepted on a punk
     * @param punkId id of punk
     */
    event AccetPunkBid(uint256 punkId);

    /**
     * @notice emitted when a punk is listed on crypto punk marketplace
     * @param punkId id of punk
     */
    event ListPunk(uint256 punkId);

    /**
     * @notice emitted when proceeds are received from crypto punk marketplace
     * @param proceeds amount of ETH received as proceedds
     */
    event ReceivePunkProceeds(uint256 proceeds);

    /**
     * @notice emitted when part of the staked position is unstaked to receive pETH
     * @param pETH amount of pETH received
     */
    event UnstakePETH(uint256 pETH);

    /**
     * @notice emitted when part of the staked position is unstaked to receive pUSD
     * @param pUSD amount of pUSD received
     */
    event UnstakePUSD(uint256 pUSD);

    /**
     * @notice emitted when yield is provided in a PETH vault
     * @param providedETH amount of ETH provided
     * @param providedJPEG amount of JPEG provided
     */
    event ProvideYieldPETH(uint256 providedETH, uint256 providedJPEG);
}
