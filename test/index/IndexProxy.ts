import { ethers } from 'hardhat';
import {
  ICore,
  ICore__factory,
  Core__factory,
  IERC20__factory,
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
  IVault__factory,
  IndexView__factory,
} from '../../typechain-types';
import { getBalancerContractAddress } from '@balancer-labs/v2-deployments';

import { BigNumber, ContractTransaction } from 'ethers';

import { describeBehaviorOfIndexProxy } from '../../spec/index/IndexProxy.behavior';

describe('IndexProxy', () => {
  let snapshotId: number;

  let core: ICore;
  let instance: IIndex;
  const tokensArg: string[] = [];
  const weightsArg: BigNumber[] = [];
  const amountsArg: BigNumber[] = [];
  let BALANCER_VAULT = '';
  let INVESTMENT_POOL_FACTORY = '';
  let BALANCER_HELPERS = '0x77d46184d22CA6a3726a2F500c776767b6A3d6Ab'; //arbitrum

  before(async () => {
    const [deployer] = await ethers.getSigners();
    BALANCER_VAULT = await getBalancerContractAddress(
      '20210418-vault',
      'Vault',
      'arbitrum',
    );
    INVESTMENT_POOL_FACTORY = await getBalancerContractAddress(
      '20210907-investment-pool',
      'InvestmentPoolFactory',
      'arbitrum',
    );

    const coreDiamond = await new Core__factory(deployer).deploy();

    const indexDiamond = await new IndexDiamond__factory(deployer).deploy();

    const coreFacetCuts = [
      await new IndexManager__factory(deployer).deploy(
        indexDiamond.address,
        INVESTMENT_POOL_FACTORY,
        BALANCER_VAULT,
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

    const indexFacetCuts = [
      await new IndexBase__factory(deployer).deploy(
        BALANCER_VAULT,
        BALANCER_HELPERS,
      ),
      await new IndexIO__factory(deployer).deploy(
        BALANCER_VAULT,
        BALANCER_HELPERS,
      ),
      await new IndexView__factory(deployer).deploy(
        BALANCER_VAULT,
        BALANCER_HELPERS,
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
        'token1',
        'T1',
        ethers.BigNumber.from('18'),
        ethers.utils.parseEther('10000'),
      ),
      await new SolidStateERC20Mock__factory(deployer).deploy(
        'token2',
        'T2',
        ethers.BigNumber.from('18'),
        ethers.utils.parseEther('10000'),
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
        .approve(core.address, ethers.constants.MaxUint256);
    }

    const deployIndexTx = await core
      .connect(deployer)
      .deployIndex(tokensArg, weightsArg, amountsArg, ethers.constants.Zero);

    const { events } = await deployIndexTx.wait();
    const { deployment } = events.find((e) => e.event === 'IndexDeployed').args;

    instance = IIndex__factory.connect(deployment, deployer);

    const balancerVault = IVault__factory.connect(BALANCER_VAULT, deployer);

    await balancerVault
      .connect(deployer)
      .setRelayerApproval(deployer.address, instance.address, true);
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
      await instance['__mint(address,uint256)'](recipient, amount),
    burn: async (recipient, amount) =>
      await instance['__burn(address,uint256)'](recipient, amount),
    allowance: (holder, spender) =>
      instance.callStatic.allowance(holder, spender),
    mintAsset: async () => {
      return {} as unknown as Promise<ContractTransaction>;
    },
    name: 'string',
    symbol: 'string',
    decimals: ethers.BigNumber.from('18'),
    supply: ethers.constants.Zero,

    tokens: tokensArg,
    weights: weightsArg,

    implementationFunction: 'name()',
    implementationFunctionArgs: [],
  });
});
