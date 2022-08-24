import hre, { ethers } from 'hardhat';
import {
  ICore,
  ICore__factory,
  Core__factory,
  IERC20,
  IERC20__factory,
  IERC20Metadata__factory,
  IIndex,
  IIndex__factory,
  IndexDiamond__factory,
  IndexManager__factory,
  IndexBase__factory,
  IndexIO__factory,
  SolidStateERC20Mock__factory,
  IVault,
  IVault__factory,
  IndexView__factory,
  IndexSettings__factory,
  Swapper__factory,
} from '../../typechain-types';
import { getBalancerContractAddress } from '@balancer-labs/v2-deployments';

import { BigNumber, ContractTransaction } from 'ethers';

import { describeBehaviorOfERC20Metadata } from '@solidstate/spec';
import { describeBehaviorOfIndexProxy } from '../../spec/index/IndexProxy.behavior';
import { defaultAbiCoder } from 'ethers/lib/utils';
import { expect } from 'chai';

const BALANCER_HELPERS = '0x77d46184d22CA6a3726a2F500c776767b6A3d6Ab'; //arbitrum

describe('IndexProxy', () => {
  let snapshotId: number;

  let deployer: any;
  let user1: any;
  let user2: any;
  let user3: any;

  let balancerVault: IVault;
  let core: ICore;
  let instance: IIndex;
  let balancerPool: IERC20;

  let deploymentTS: number;
  const tokensArg: string[] = [];
  const weightsArg: BigNumber[] = [];
  const amountsArg: BigNumber[] = [];
  //workaround for visibility
  const swapperArg: string[] = [];

  const id = 1;
  const EXIT_FEE_BP = ethers.utils.parseUnits('0.02', 4);
  const STREAMING_FEE_BP = ethers.utils.parseUnits('0.015', 4);

  before(async () => {
    // TODO: must skip signers because they're not parameterized in SolidState spec
    [, , , deployer, user1, user2, user3] = await ethers.getSigners();

    const balancerVaultAddress = await getBalancerContractAddress(
      '20210418-vault',
      'Vault',
      'arbitrum',
    );

    const investmentPoolFactoryAddress = await getBalancerContractAddress(
      '20210907-investment-pool',
      'InvestmentPoolFactory',
      'arbitrum',
    );

    balancerVault = IVault__factory.connect(balancerVaultAddress, deployer);

    const swapper = await new Swapper__factory(deployer).deploy();
    swapperArg.push(swapper.address);

    const coreDiamond = await new Core__factory(deployer).deploy();

    const indexDiamond = await new IndexDiamond__factory(deployer).deploy();
    const coreFacetCuts = [
      await new IndexManager__factory(deployer).deploy(
        indexDiamond.address,
        investmentPoolFactoryAddress,
        balancerVault.address,
      ),
    ].map(function (f) {
      return {
        target: f.address,
        action: 0,
        selectors: Object.keys(f.interface.functions).map((fn) =>
          f.interface.getSighash(fn),
        ),
      };
    });

    const indexSelectors = new Set();

    const indexFacetCuts = [
      await new IndexBase__factory(deployer).deploy(
        balancerVault.address,
        BALANCER_HELPERS,
        swapper.address,
        EXIT_FEE_BP,
        STREAMING_FEE_BP,
      ),
      await new IndexIO__factory(deployer).deploy(
        balancerVault.address,
        BALANCER_HELPERS,
        swapper.address,
        EXIT_FEE_BP,
        STREAMING_FEE_BP,
      ),
      await new IndexView__factory(deployer).deploy(
        balancerVault.address,
        BALANCER_HELPERS,
        swapper.address,
        EXIT_FEE_BP,
        STREAMING_FEE_BP,
      ),
      await new IndexSettings__factory(deployer).deploy(
        balancerVault.address,
        BALANCER_HELPERS,
        swapper.address,
        EXIT_FEE_BP,
        STREAMING_FEE_BP,
      ),
      await new SolidStateERC20Mock__factory(deployer).deploy('', ''),
    ].map(function (f) {
      return {
        target: f.address,
        action: 0,
        selectors: Object.keys(f.interface.functions)
          .filter((fn) => !indexSelectors.has(fn) && indexSelectors.add(fn))
          .map((fn) => f.interface.getSighash(fn)),
      };
    });

    await coreDiamond.diamondCut(
      coreFacetCuts,
      ethers.constants.AddressZero,
      '0x',
    );

    await indexDiamond.diamondCut(
      indexFacetCuts,
      ethers.constants.AddressZero,
      '0x',
    );

    core = ICore__factory.connect(coreDiamond.address, ethers.provider);

    const tokens = [
      await new SolidStateERC20Mock__factory(deployer).deploy(
        'test token one',
        'TT1',
      ),
      await new SolidStateERC20Mock__factory(deployer).deploy(
        'test token two',
        'TT2',
      ),
    ];

    const tokenAddresses = tokens
      .map((el) => el.address)
      .sort((a, b) =>
        parseFloat(
          ethers.BigNumber.from(a).sub(ethers.BigNumber.from(b)).toString(),
        ),
      );

    const weights = tokens.map((el) => ethers.utils.parseEther('0.5'));

    for (let i = 0; i < tokenAddresses.length; i++) {
      tokensArg.push(tokenAddresses[i]);
      weightsArg.push(weights[i]);
      amountsArg.push(
        ethers.utils
          .parseEther('1')
          .mul(weights[i])
          .div(ethers.utils.parseEther('1')),
      );
    }

    for (let i = 0; i < tokens.length; i++) {
      await tokens[i]
        .connect(deployer)
        .__mint(deployer.address, ethers.utils.parseEther('10000'));
      await tokens[i]
        .connect(deployer)
        .approve(core.address, ethers.constants.MaxUint256);
      await tokens[i]
        .connect(deployer)
        .approve(balancerVault.address, ethers.constants.MaxUint256);
    }

    const deployIndexTx = await core
      .connect(deployer)
      .deployIndex(tokensArg, weightsArg, amountsArg);

    const { events, blockNumber } = await deployIndexTx.wait();
    const { deployment } = events.find((e) => e.event === 'IndexDeployed').args;
    const { timestamp } = await ethers.provider.getBlock(blockNumber);

    deploymentTS = timestamp;

    instance = IIndex__factory.connect(deployment, deployer);

    balancerPool = IERC20__factory.connect(
      await instance.callStatic.asset(),
      deployer,
    );
  });

  beforeEach(async () => {
    snapshotId = await ethers.provider.send('evm_snapshot', []);
  });

  afterEach(async () => {
    await ethers.provider.send('evm_revert', [snapshotId]);
  });

  describeBehaviorOfIndexProxy(async () => instance, {
    getProtocolOwner: async () => deployer,
    // TODO: replace circular `asset` logic with Balancer event output
    getAsset: async () =>
      IERC20__factory.connect(
        await (
          await IIndex__factory.connect(instance.address, ethers.provider)
        ).callStatic.asset(),
        ethers.provider,
      ),
    mint: async (recipient, amount) =>
      await SolidStateERC20Mock__factory.connect(instance.address, deployer)[
        '__mint(address,uint256)'
      ](recipient, amount),
    burn: async (recipient, amount) =>
      await SolidStateERC20Mock__factory.connect(instance.address, deployer)[
        '__burn(address,uint256)'
      ](recipient, amount),
    allowance: (holder, spender) =>
      instance.callStatic.allowance(holder, spender),
    mintAsset: async (recipient, amount) => {
      const maxAmountsIn = await Promise.all(
        tokensArg.map((t) =>
          IERC20__factory.connect(t, ethers.provider).callStatic.balanceOf(
            deployer.address,
          ),
        ),
      );
      // use JoinKind EXACT_TOKENS_IN_FOR_BPT_OUT
      const userData = defaultAbiCoder.encode(
        ['uint256', 'uint256[]', 'uint256'],
        [ethers.BigNumber.from('1'), maxAmountsIn, amount],
      );

      const request = {
        assets: tokensArg,
        maxAmountsIn: maxAmountsIn,
        userData: userData,
        fromInternalBalance: false,
      };

      await balancerVault
        .connect(deployer)
        .joinPool(
          await instance.callStatic.getPoolId(),
          deployer.address,
          deployer.address,
          request,
        );

      return await balancerPool.connect(deployer).transfer(recipient, amount);
    },
    name: `Insrt Finance InfraIndex #${id}`,
    symbol: `IFII-${id}`,
    decimals: ethers.BigNumber.from('18'),
    // TODO: update SolidState to prevent need for magic number
    supply: ethers.BigNumber.from('0x0de0b6b39db5e1ea'),

    tokens: tokensArg,
    weights: weightsArg,
    swapper: swapperArg,
    streamingFeeBP: STREAMING_FEE_BP,
    exitFeeBP: EXIT_FEE_BP,

    implementationFunction: 'name()',
    implementationFunctionArgs: [],
  });

  describe('base BPT asset', () => {
    describeBehaviorOfERC20Metadata(
      async () =>
        IERC20Metadata__factory.connect(balancerPool.address, ethers.provider),
      {
        name: `IFII-BPT-${id}`,
        symbol: `IFII-BPT-${id}`,
        decimals: ethers.BigNumber.from('18'),
      },
    );
  });

  describe('multiple deposit and withdrawal scenarios', () => {
    const mintAmount = ethers.utils.parseEther('100000000');
    const timestep = 100;

    const BASIS = ethers.utils.parseUnits('1', 4);
    const EXIT_FEE_FACTOR_64x64 = BASIS.sub(EXIT_FEE_BP).shl(64).div(BASIS);
    const STREAMING_FEE_FACTOR_PER_SECOND_64x64 = ethers.constants.One.shl(
      64,
    ).sub(
      STREAMING_FEE_BP.shl(64)
        .div(365.25 * 86400)
        .div(BASIS),
    );

    const poolTokenAmounts: BigNumber[] = [];
    let totalWeight: BigNumber = BigNumber.from('0');

    before(async () => {
      const tokens = await Promise.all(
        tokensArg.map(
          async (t) => await ethers.getContractAt('SolidStateERC20Mock', t),
        ),
      );

      for (let i = 0; i < tokens.length; i++) {
        await tokens[i].__mint(user1.address, mintAmount);
        await tokens[i].__mint(user2.address, mintAmount);
        await tokens[i].__mint(user3.address, mintAmount);

        await tokens[i]
          .connect(user1)
          ['increaseAllowance(address,uint256)'](
            instance.address,
            ethers.constants.MaxUint256,
          );
        await tokens[i]
          .connect(user2)
          ['increaseAllowance(address,uint256)'](
            instance.address,
            ethers.constants.MaxUint256,
          );
        await tokens[i]
          .connect(user3)
          ['increaseAllowance(address,uint256)'](
            instance.address,
            ethers.constants.MaxUint256,
          );
      }

      totalWeight = weightsArg.reduce((a, b) => {
        return a.add(b);
      });

      for (let i = 0; i < tokensArg.length; i++) {
        let unweightedAmount = ethers.utils.parseEther('0.01');
        let depositAmount = unweightedAmount
          .mul(weightsArg[i])
          .div(totalWeight);
        poolTokenAmounts.push(depositAmount);
      }
    });

    it('accounts for feesAccrued after sequential deposits', async () => {
      const minBptOut = ethers.utils.parseUnits('1', 'gwei');

      const deposit1TS = deploymentTS + timestep;
      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        deposit1TS,
      ]);

      await instance
        .connect(user1)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          user1.address,
        );

      const user1Balance = await instance.callStatic['balanceOf(address)'](
        user1.address,
      );
      let totalSupply = await instance.callStatic['totalSupply()']();
      let supplyChange = totalSupply.sub(user1Balance);

      let streamingFees = supplyChange.sub(
        supplyChange
          .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(timestep))
          .shr(64 * timestep),
      );

      expect(streamingFees).to.eq(await instance.feesAccrued());

      const deposit2TS = deposit1TS + timestep;

      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        deposit2TS,
      ]);

      await instance
        .connect(user2)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          user2.address,
        );

      const user2Balance = await instance.callStatic['balanceOf(address)'](
        user2.address,
      );
      totalSupply = await instance.callStatic['totalSupply()']();
      supplyChange = totalSupply.sub(user2Balance);

      streamingFees = streamingFees.add(
        supplyChange.sub(
          supplyChange
            .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(timestep))
            .shr(64 * timestep),
        ),
      );

      expect(streamingFees).to.eq(await instance.feesAccrued());

      const deposit3TS = deposit2TS + timestep;
      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        deposit3TS,
      ]);

      await instance
        .connect(user3)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          user3.address,
        );

      const user3Balance = await instance.callStatic['balanceOf(address)'](
        user3.address,
      );
      totalSupply = await instance.callStatic['totalSupply()']();
      supplyChange = totalSupply.sub(user3Balance);

      streamingFees = streamingFees.add(
        supplyChange.sub(
          supplyChange
            .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(timestep))
            .shr(64 * timestep),
        ),
      );

      expect(streamingFees).to.eq(await instance.feesAccrued());
    });

    it('accounts for feesAccrued after sequential deposits and sequential redeems', async () => {
      const minBptOut = ethers.utils.parseUnits('1', 'gwei');

      const deposit1TS = deploymentTS + timestep;
      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        deposit1TS,
      ]);

      await instance
        .connect(user1)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          user1.address,
        );

      const shares1 = await instance.callStatic['balanceOf(address)'](
        user1.address,
      );
      let totalSupply = await instance.callStatic['totalSupply()']();
      let supplyChange = totalSupply.sub(shares1);

      let streamingFees = supplyChange.sub(
        supplyChange
          .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(timestep))
          .shr(64 * timestep),
      );

      expect(streamingFees).to.eq(await instance.feesAccrued());

      const deposit2TS = deposit1TS + timestep;

      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        deposit2TS,
      ]);

      await instance
        .connect(user2)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          user2.address,
        );

      const shares2 = await instance.callStatic['balanceOf(address)'](
        user2.address,
      );
      totalSupply = await instance.callStatic['totalSupply()']();
      supplyChange = totalSupply.sub(shares2);

      streamingFees = streamingFees.add(
        supplyChange.sub(
          supplyChange
            .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(timestep))
            .shr(64 * timestep),
        ),
      );

      expect(streamingFees).to.eq(await instance.feesAccrued());

      const deposit3TS = deposit2TS + timestep;
      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        deposit3TS,
      ]);

      await instance
        .connect(user3)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          user3.address,
        );

      const shares3 = await instance.callStatic['balanceOf(address)'](
        user3.address,
      );
      totalSupply = await instance.callStatic['totalSupply()']();
      supplyChange = totalSupply.sub(shares3);

      streamingFees = streamingFees.add(
        supplyChange.sub(
          supplyChange
            .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(timestep))
            .shr(64 * timestep),
        ),
      );

      expect(streamingFees).to.eq(await instance.feesAccrued());

      const redeem1TS = deposit3TS + timestep;
      await hre.network.provider.send('evm_setNextBlockTimestamp', [redeem1TS]);

      const minPoolTokenAmounts = [minBptOut, minBptOut];

      await instance
        .connect(user1)
        ['redeem(uint256,uint256[],address)'](
          shares1,
          minPoolTokenAmounts,
          user1.address,
        );

      //duration for the user and the protocol are different
      let protocolDuration = redeem1TS - deposit3TS;
      let duration = redeem1TS - deposit1TS;
      let amountAfterStreamingFee = shares1
        .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(duration))
        .shr(64 * duration);

      let amountAfterExitFee = amountAfterStreamingFee
        .mul(EXIT_FEE_FACTOR_64x64)
        .shr(64);

      let exitFee = amountAfterStreamingFee.sub(amountAfterExitFee);

      let protocolStreamingFees = shares1.sub(
        shares1
          .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(protocolDuration))
          .shr(64 * protocolDuration),
      );

      streamingFees = streamingFees.add(protocolStreamingFees);

      let fees = exitFee.add(streamingFees);

      expect(fees).to.eq(await instance.feesAccrued());

      const redeem2TS = redeem1TS + timestep;
      await hre.network.provider.send('evm_setNextBlockTimestamp', [redeem2TS]);

      await instance
        .connect(user2)
        ['redeem(uint256,uint256[],address)'](
          shares2,
          minPoolTokenAmounts,
          user2.address,
        );

      //duration for the user and the protocol are different
      protocolDuration = redeem2TS - deposit3TS;
      duration = redeem2TS - deposit2TS;
      amountAfterStreamingFee = shares2
        .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(duration))
        .shr(64 * duration);

      amountAfterExitFee = amountAfterStreamingFee
        .mul(EXIT_FEE_FACTOR_64x64)
        .shr(64);

      exitFee = amountAfterStreamingFee.sub(amountAfterExitFee);

      protocolStreamingFees = shares2.sub(
        shares2
          .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(protocolDuration))
          .shr(64 * protocolDuration),
      );

      fees = fees.add(protocolStreamingFees).add(exitFee);

      expect(fees).to.eq(await instance.feesAccrued());

      const redeem3TS = redeem2TS + timestep;
      await hre.network.provider.send('evm_setNextBlockTimestamp', [redeem3TS]);

      await instance
        .connect(user3)
        ['redeem(uint256,uint256[],address)'](
          shares3,
          minPoolTokenAmounts,
          user2.address,
        );

      //duration for the user and the protocol are different
      protocolDuration = redeem3TS - deposit3TS;
      duration = redeem3TS - deposit3TS;
      amountAfterStreamingFee = shares3
        .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(duration))
        .shr(64 * duration);

      amountAfterExitFee = amountAfterStreamingFee
        .mul(EXIT_FEE_FACTOR_64x64)
        .shr(64);

      exitFee = amountAfterStreamingFee.sub(amountAfterExitFee);

      protocolStreamingFees = shares3.sub(
        shares3
          .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(protocolDuration))
          .shr(64 * protocolDuration),
      );

      fees = fees.add(protocolStreamingFees).add(exitFee);

      expect(fees).to.eq(await instance.feesAccrued());
    });

    it('accounts for fees accrued during non-sequential deposits, redeems and withdrawals', async () => {
      const minBptOut = ethers.utils.parseUnits('1', 'gwei');

      const deposit1TS = deploymentTS + timestep;
      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        deposit1TS,
      ]);

      await instance
        .connect(user1)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          user1.address,
        );

      const shares1 = await instance.callStatic['balanceOf(address)'](
        user1.address,
      );
      let totalSupply = await instance.callStatic['totalSupply()']();
      let supplyChange = totalSupply.sub(shares1);

      let streamingFees = supplyChange.sub(
        supplyChange
          .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(timestep))
          .shr(64 * timestep),
      );

      expect(streamingFees).to.eq(await instance.feesAccrued());

      const deposit2TS = deposit1TS + timestep;

      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        deposit2TS,
      ]);

      await instance
        .connect(user2)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          user2.address,
        );

      const shares2 = await instance.callStatic['balanceOf(address)'](
        user2.address,
      );
      totalSupply = await instance.callStatic['totalSupply()']();
      supplyChange = totalSupply.sub(shares2);

      streamingFees = streamingFees.add(
        supplyChange.sub(
          supplyChange
            .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(timestep))
            .shr(64 * timestep),
        ),
      );

      expect(streamingFees).to.eq(await instance.feesAccrued());

      const redeem2TS = deposit2TS + timestep;
      await hre.network.provider.send('evm_setNextBlockTimestamp', [redeem2TS]);

      const minPoolTokenAmounts = [minBptOut, minBptOut];

      await instance
        .connect(user2)
        ['redeem(uint256,uint256[],address)'](
          shares2,
          minPoolTokenAmounts,
          user1.address,
        );

      //duration for the user and the protocol are different
      let protocolDuration = redeem2TS - deposit2TS;
      let duration = redeem2TS - deposit2TS;
      let amountAfterStreamingFee = shares2
        .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(duration))
        .shr(64 * duration);

      let amountAfterExitFee = amountAfterStreamingFee
        .mul(EXIT_FEE_FACTOR_64x64)
        .shr(64);

      let exitFee = amountAfterStreamingFee.sub(amountAfterExitFee);

      let protocolStreamingFees = shares2.sub(
        shares2
          .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(protocolDuration))
          .shr(64 * protocolDuration),
      );

      streamingFees = streamingFees.add(protocolStreamingFees);

      let fees = exitFee.add(streamingFees);

      expect(fees).to.eq(await instance.feesAccrued());

      const deposit3TS = redeem2TS + timestep;
      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        deposit3TS,
      ]);

      await instance
        .connect(user3)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          user3.address,
        );

      //protocolDuration is no longer simply timestep  because of the sequence of deposits/withdrawals
      protocolDuration = deposit3TS - deposit2TS;
      const shares3 = await instance.callStatic['balanceOf(address)'](
        user3.address,
      );
      totalSupply = await instance.callStatic['totalSupply()']();
      supplyChange = totalSupply.sub(shares3);

      fees = fees.add(
        supplyChange.sub(
          supplyChange
            .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(protocolDuration))
            .shr(64 * protocolDuration),
        ),
      );

      expect(fees).to.eq(await instance.feesAccrued());

      const redeem3TS = deposit3TS + timestep;
      await hre.network.provider.send('evm_setNextBlockTimestamp', [redeem3TS]);

      await instance
        .connect(user3)
        ['redeem(uint256,uint256[],address)'](
          shares3,
          minPoolTokenAmounts,
          user3.address,
        );

      //duration for the user and the protocol are different
      protocolDuration = redeem3TS - deposit3TS;
      duration = redeem3TS - deposit3TS;
      amountAfterStreamingFee = shares3
        .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(duration))
        .shr(64 * duration);

      amountAfterExitFee = amountAfterStreamingFee
        .mul(EXIT_FEE_FACTOR_64x64)
        .shr(64);

      exitFee = amountAfterStreamingFee.sub(amountAfterExitFee);

      protocolStreamingFees = shares3.sub(
        shares3
          .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(protocolDuration))
          .shr(64 * protocolDuration),
      );

      fees = fees.add(exitFee).add(protocolStreamingFees);

      expect(fees).to.eq(await instance.feesAccrued());

      const redeem1TS = redeem3TS + timestep;
      await hre.network.provider.send('evm_setNextBlockTimestamp', [redeem1TS]);

      await instance
        .connect(user1)
        ['redeem(uint256,uint256[],address)'](
          shares1,
          minPoolTokenAmounts,
          user1.address,
        );

      //duration for the user and the protocol are different
      protocolDuration = redeem1TS - deposit3TS;
      duration = redeem1TS - deposit1TS;
      amountAfterStreamingFee = shares1
        .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(duration))
        .shr(64 * duration);

      amountAfterExitFee = amountAfterStreamingFee
        .mul(EXIT_FEE_FACTOR_64x64)
        .shr(64);

      exitFee = amountAfterStreamingFee.sub(amountAfterExitFee);

      protocolStreamingFees = shares1.sub(
        shares1
          .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(protocolDuration))
          .shr(64 * protocolDuration),
      );

      fees = fees.add(exitFee).add(protocolStreamingFees);

      expect(fees).to.eq(await instance.feesAccrued());
    });
  });
});
