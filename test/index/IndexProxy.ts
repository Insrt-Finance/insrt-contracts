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

import { BigNumber, ContractTransaction } from 'ethers';

import { describeBehaviorOfIndexProxy } from '../../spec/index/IndexProxy.behavior';

describe.only('IndexProxy', () => {
  let snapshotId: number;

  let core: ICore;
  let instance: IIndex;
  const tokensArg: string[] = [];
  const weightsArg: BigNumber[] = [];
  const BALANCER_VAULT = '0xBA12222222228d8Ba445958a75a0704d566BF2C8'; //arbitrum
  const BALANCER_HELPERS = '0x77d46184d22CA6a3726a2F500c776767b6A3d6Ab'; //arbitrum

  before(async () => {
    const [deployer] = await ethers.getSigners();

    const coreDiamond = await new Core__factory(deployer).deploy();

    const indexDiamond = await new IndexDiamond__factory(deployer).deploy();

    const coreFacetCuts = [
      await new IndexManager__factory(deployer).deploy(
        indexDiamond.address,
        '0xaCd615B3705B9c880E4E7293f1030B34e57B4c1c', // abitrum mainnet address
        // '0x48767F9F868a4A7b86A90736632F6E44C2df7fa9', ethereum mainnet address
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
        ethers.constants.Zero,
      ),
      await new SolidStateERC20Mock__factory(deployer).deploy(
        'token2',
        'T2',
        ethers.BigNumber.from('18'),
        ethers.constants.Zero,
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
    }

    const deployIndexTx = await core
      .connect(deployer)
      ['deployIndex(address[],uint256[],uint16)'](
        tokensArg,
        weightsArg,
        ethers.constants.Zero,
      );

    const { events } = await deployIndexTx.wait();
    const { deployment } = events.find((e) => e.event === 'IndexDeployed').args;

    instance = IIndex__factory.connect(deployment, deployer);

    const balancerVault = IVault__factory.connect(BALANCER_VAULT, deployer);

    await balancerVault
      .connect(deployer)
      .setRelayerApproval(deployer.address, instance.address, true);

    await tokens[0]
      .connect(deployer)
      ['approve(address,uint256)'](
        BALANCER_VAULT,
        ethers.utils.parseEther('10'),
      );
    await tokens[1]
      .connect(deployer)
      ['approve(address,uint256)'](
        BALANCER_VAULT,
        ethers.utils.parseEther('10'),
      );
    // checking to see if balances are non-zero after initialization
    //console.log(await balancerVault.getPoolTokens(await instance.callStatic['getPoolId()']()));
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
