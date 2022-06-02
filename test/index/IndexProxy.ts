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
} from '../../typechain-types';

import { ContractTransaction } from 'ethers';

import { InsrtToken__factory } from '../../typechain-types';

import { describeBehaviorOfIndexProxy } from '../../spec/index/IndexProxy.behavior';

describe('IndexProxy', () => {
  let snapshotId: number;

  let core: ICore;
  let instance: IIndex;

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
        ethers.constants.AddressZero,
        ethers.constants.AddressZero,
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

    core = await ICore__factory.connect(coreDiamond.address, ethers.provider);

    const tokens = [
      await new InsrtToken__factory(deployer).deploy(deployer.address),
      await new InsrtToken__factory(deployer).deploy(deployer.address),
    ];

    const deployIndexTx = await core.connect(deployer).deployIndex(
      tokens
        .map((el) => el.address)
        .sort((a, b) =>
          parseFloat(
            ethers.BigNumber.from(a).sub(ethers.BigNumber.from(b)).toString(),
          ),
        ),
      tokens.map((el) => ethers.utils.parseEther('0.5')),

      ethers.constants.Zero,
    );

    const { events } = await deployIndexTx.wait();
    const { deployment } = events.find((e) => e.event === 'IndexDeployed').args;

    const indexProxy = await IndexProxy__factory.connect(
      deployment,
      ethers.provider,
    );

    instance = indexProxy as unknown as IIndex;
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

    implementationFunction: 'name()',
    implementationFunctionArgs: [],
  });
});
