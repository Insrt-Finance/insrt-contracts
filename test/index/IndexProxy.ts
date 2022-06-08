import { ethers } from 'hardhat';
import {
  ICore,
  ICore__factory,
  Core__factory,
  IERC20,
  IERC20__factory,
  IERC20Metadata__factory,
  IIndex,
  IIndex__factory,
  IndexDiamond,
  IndexDiamond__factory,
  IndexManager__factory,
  IndexBase__factory,
  IndexProxy,
  IndexProxy__factory,
  IndexIO__factory,
  SolidStateERC20Mock__factory,
  IVault,
  IVault__factory,
  IndexView__factory,
} from '../../typechain-types';
import { getBalancerContractAddress } from '@balancer-labs/v2-deployments';

import { BigNumber, ContractTransaction } from 'ethers';

import { describeBehaviorOfERC20Metadata } from '@solidstate/spec';
import { describeBehaviorOfIndexProxy } from '../../spec/index/IndexProxy.behavior';

const BALANCER_HELPERS = '0x77d46184d22CA6a3726a2F500c776767b6A3d6Ab'; //arbitrum

describe('IndexProxy', () => {
  let snapshotId: number;

  let deployer: any;

  let balancerVault: IVault;
  let core: ICore;
  let instance: IIndex;
  let balancerPool: IERC20;

  const tokensArg: string[] = [];
  const weightsArg: BigNumber[] = [];
  const amountsArg: BigNumber[] = [];

  const id = 1;

  before(async () => {
    [deployer] = await ethers.getSigners();

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
      ),
      await new IndexIO__factory(deployer).deploy(
        balancerVault.address,
        BALANCER_HELPERS,
      ),
      await new IndexView__factory(deployer).deploy(
        balancerVault.address,
        BALANCER_HELPERS,
      ),
      await new SolidStateERC20Mock__factory(deployer).deploy(),
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
      await new SolidStateERC20Mock__factory(deployer).deploy(),
      await new SolidStateERC20Mock__factory(deployer).deploy(),
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
        .__mint(deployer.address, ethers.utils.parseUnits('10000', 18));
      await tokens[i]
        .connect(deployer)
        .approve(core.address, ethers.constants.MaxUint256);
      await tokens[i]
        .connect(deployer)
        .approve(balancerVault.address, ethers.constants.MaxUint256);
    }

    const deployIndexTx = await core
      .connect(deployer)
      .deployIndex(tokensArg, weightsArg, amountsArg, ethers.constants.Zero);

    const { events } = await deployIndexTx.wait();
    const { deployment } = events.find((e) => e.event === 'IndexDeployed').args;

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
      // use JoinKind ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
      const userData = ethers.utils.solidityPack(
        ['uint256', 'uint256'],
        [ethers.BigNumber.from('3'), amount],
      );

      const request = {
        assets: tokensArg,
        maxAmountsIn: await Promise.all(
          tokensArg.map((t) =>
            IERC20__factory.connect(t, ethers.provider).callStatic.balanceOf(
              deployer.address,
            ),
          ),
        ),
        userData,
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

      return await balancerPool.transfer(recipient, amount);
    },
    name: `Insrt Finance InfraIndex #${id}`,
    symbol: `IFII-${id}`,
    decimals: ethers.BigNumber.from('18'),
    supply: ethers.constants.Zero,

    tokens: tokensArg,
    weights: weightsArg,

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
});
